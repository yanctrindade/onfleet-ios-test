import Foundation

// MARK: - Redux Protocol Definitions

protocol ReduxState: Equatable {}

protocol ReduxAction {}

protocol ReduxReducer {
    associatedtype State: ReduxState
    associatedtype Action: ReduxAction
    
    func reduce(state: State, action: Action) -> State
}

// MARK: - Effect System (for future use)

struct Effect<Action> {
    let operation: (@escaping (Action) -> Void) async -> Void
    
    static func none() -> Effect<Action> {
        return Effect { _ in }
    }
    
    static func run(operation: @escaping (@escaping (Action) -> Void) async -> Void) -> Effect<Action> {
        return Effect(operation: operation)
    }
}

// MARK: - Store Implementation

@MainActor
final class Store<State: ReduxState, Action: ReduxAction>: ObservableObject {
    @Published private(set) var state: State
    
    private var reducer: AnyReducer<State, Action>
    
    init<R: ReduxReducer>(initialState: State, reducer: R) where R.State == State, R.Action == Action {
        self.state = initialState
        self.reducer = AnyReducer(reducer)
    }
    
    func send(_ action: Action) {
        let newState = reducer.reduce(state: state, action: action)
        if newState != state {
            state = newState
        }
        
        // Handle effects if needed
        handleEffects(for: action)
    }
    
    private func handleEffects(for action: Action) {
        // Simple effect handling - can be expanded
        Task { @MainActor in
            // Effects would be handled here
        }
    }
}

// MARK: - Type Erasure for Reducer

private struct AnyReducer<State: ReduxState, Action: ReduxAction> {
    private let _reduce: (State, Action) -> State
    
    init<R: ReduxReducer>(_ reducer: R) where R.State == State, R.Action == Action {
        self._reduce = reducer.reduce
    }
    
    func reduce(state: State, action: Action) -> State {
        return _reduce(state, action)
    }
}

