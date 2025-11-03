import Foundation
import ComposableArchitecture

// MARK: - TCA Store Factory
// Helper to create TCA stores with our specific configuration

typealias PhoneBookStore = StoreOf<PhoneBookFeature>

// MARK: - Store Creation Helper
extension Store where State == PhoneBookFeature.State, Action == PhoneBookFeature.Action {
    
    static func phoneBookStore() -> PhoneBookStore {
        return Store(initialState: PhoneBookFeature.State()) {
            PhoneBookFeature()
        }
    }
}

