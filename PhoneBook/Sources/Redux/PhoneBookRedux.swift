import Foundation

// MARK: - PhoneBook State

struct PhoneBookState: ReduxState {
    var records: [PhoneBookRecord] = []
    var filteredRecords: [PhoneBookRecord] = []
    var searchText: String? = nil
    var isRandomizing: Bool = false
    
    static let initial = PhoneBookState()
}

// MARK: - PhoneBook Actions

enum PhoneBookAction: ReduxAction {
    case viewDidLoad
    case searchTextChanged(String)
    case randomizeButtonTapped
    case randomizationCompleted
    case recordsUpdated([PhoneBookRecord])
    case recordsFiltered([PhoneBookRecord])
}

// MARK: - PhoneBook Reducer

struct PhoneBookReducer: ReduxReducer {
    typealias State = PhoneBookState
    typealias Action = PhoneBookAction
    
    func reduce(state: PhoneBookState, action: PhoneBookAction) -> PhoneBookState {
        var newState = state
        
        switch action {
        case .viewDidLoad:
            // Initial state is already set
            break
            
        case .searchTextChanged(let text):
            newState.searchText = text.isEmpty ? nil : text
            newState.filteredRecords = filterRecords(newState.records, searchText: text)
            
        case .randomizeButtonTapped:
            newState.isRandomizing = true
            
        case .recordsUpdated(let records):
            var newState = state
            newState.records = records
            
            // Apply current filter to new records
            if let searchText = newState.searchText, !searchText.isEmpty {
                newState.filteredRecords = records.filter {
                    $0.detail.name.localizedCaseInsensitiveContains(searchText) ||
                    $0.contact.phoneNumber.localizedCaseInsensitiveContains(searchText)
                }
            } else {
                newState.filteredRecords = records
            }
            
            return newState
            
        case .recordsFiltered(let filteredRecords):
            var newState = state
            newState.filteredRecords = filteredRecords
            return newState
            

            
        case .randomizationCompleted:
            newState.isRandomizing = false
        }
        
        return newState
    }
    
    private func filterRecords(_ records: [PhoneBookRecord], searchText: String) -> [PhoneBookRecord] {
        guard !searchText.isEmpty else { return records }
        
        return records.filter {
            $0.detail.name.localizedCaseInsensitiveContains(searchText) ||
            $0.contact.phoneNumber.localizedCaseInsensitiveContains(searchText)
        }
    }
}