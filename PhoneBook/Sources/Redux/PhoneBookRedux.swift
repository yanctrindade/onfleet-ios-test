import Foundation
import Combine
import Fakery
import ComposableArchitecture

// MARK: - TCA Feature
@Reducer
struct PhoneBookFeature {
    
    // MARK: - State
    @ObservableState
    struct State: Equatable {
        var records: [PhoneBookRecord] = []
        var filteredRecords: [PhoneBookRecord] = []
        var searchText: String? = nil
        var isRandomizing: Bool = false
    }
    
    // MARK: - Actions
    enum Action {
        case viewDidLoad
        case searchTextChanged(String)
        case randomizeButtonTapped
        case randomizationCompleted
        case recordsUpdated([PhoneBookRecord])
        case recordsFiltered([PhoneBookRecord])
        case addRecord(NewPhoneBookRecord)
        case recordAdded(PhoneBookRecord)
        case loadInitialData
    }
    
    // MARK: - Dependencies
    @Dependency(\.phoneBookSource) var phoneBookSource
    
    // MARK: - Reducer Body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .viewDidLoad:
                return .send(.loadInitialData)
                
            case .searchTextChanged(let text):
                state.searchText = text.isEmpty ? nil : text
                state.filteredRecords = filterRecords(state.records, searchText: text)
                return .none
                
            case .randomizeButtonTapped:
                state.isRandomizing = true
                return .run { send in
                    await generateRandomRecords(send: send)
                }
                
            case .recordsUpdated(let records):
                state.records = records
                
                // Apply current filter to new records
                if let searchText = state.searchText, !searchText.isEmpty {
                    state.filteredRecords = records.filter {
                        $0.detail.name.localizedCaseInsensitiveContains(searchText) ||
                        $0.contact.phoneNumber.localizedCaseInsensitiveContains(searchText)
                    }
                } else {
                    state.filteredRecords = records
                }
                return .none
                
            case .recordsFiltered(let filteredRecords):
                state.filteredRecords = filteredRecords
                return .none
                
            case .addRecord(let newRecord):
                return .run { send in
                    await addSingleRecord(newRecord, send: send)
                }
                
            case .recordAdded(let record):
                state.records.append(record)
                
                // Re-apply filtering
                if let searchText = state.searchText, !searchText.isEmpty {
                    state.filteredRecords = filterRecords(state.records, searchText: searchText)
                } else {
                    state.filteredRecords = state.records
                }
                return .none
                
            case .loadInitialData:
                return .run { send in
                    await loadInitialRecords(send: send)
                }
                
            case .randomizationCompleted:
                state.isRandomizing = false
                return .none
            }
        }
    }
    
    // MARK: - Private Helper Methods
    private func filterRecords(_ records: [PhoneBookRecord], searchText: String) -> [PhoneBookRecord] {
        guard !searchText.isEmpty else { return records }
        
        return records.filter {
            $0.detail.name.localizedCaseInsensitiveContains(searchText) ||
            $0.contact.phoneNumber.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Private Effects
    private func loadInitialRecords(send: Send<PhoneBookFeature.Action>) async {
        // Load current data from source and combine it
        let details = await phoneBookSource.getCurrentDetails()
        let contacts = await phoneBookSource.getCurrentContacts()
        
        let existingRecords: [PhoneBookRecord] = details.compactMap { detail in
            guard let contact = contacts.first(where: { $0.id == detail.id }) else {
                return nil
            }
            return PhoneBookRecord(id: detail.id, detail: detail, contact: contact)
        }
        
        await send(.recordsUpdated(existingRecords))
    }
    
    private func addSingleRecord(_ newRecord: NewPhoneBookRecord, send: Send<PhoneBookFeature.Action>) async {
        // Add to source using the proper interface
        await phoneBookSource.addPerson(
            detail: PersonDetail(id: newRecord.id, name: newRecord.name),
            contact: PersonContact(id: newRecord.id, phoneNumber: newRecord.phoneNumber)
        )
        
        // Create the combined record for Redux
        let record = PhoneBookRecord(
            id: newRecord.id,
            detail: PersonDetail(id: newRecord.id, name: newRecord.name),
            contact: PersonContact(id: newRecord.id, phoneNumber: newRecord.phoneNumber)
        )
        
        // Notify Redux
        await send(.recordAdded(record))
    }
    
    private func generateRandomRecords(send: Send<PhoneBookFeature.Action>) async {
        // Import Fakery for random data generation
        let faker = Fakery.Faker()
        let records = (0..<100).map { _ in
            NewPhoneBookRecord(
                id: .init(faker.number.randomInt()),
                name: faker.name.name(),
                phoneNumber: faker.phoneNumber.phoneNumber()
            )
        }
        
        // Add records in parallel using TaskGroup (maintaining threaded behavior)
        await withTaskGroup(of: Void.self) { group in
            let numberOfThreads = 4
            let recordsPerThread = records.count / numberOfThreads
            
            for threadIndex in 0..<numberOfThreads {
                group.addTask { [phoneBookSource] in
                    let startIndex = threadIndex * recordsPerThread
                    let endIndex = (threadIndex == numberOfThreads - 1)
                    ? records.count
                    : (threadIndex + 1) * recordsPerThread
                    
                    // Each task processes its portion of records
                    for i in startIndex..<endIndex {
                        let newRecord = records[i]
                        await phoneBookSource.addPerson(
                            detail: PersonDetail(id: newRecord.id, name: newRecord.name),
                            contact: PersonContact(id: newRecord.id, phoneNumber: newRecord.phoneNumber)
                        )
                    }
                }
            }
        }
        
        // Load all records after generation by combining details and contacts
        let details = await phoneBookSource.getCurrentDetails()
        let contacts = await phoneBookSource.getCurrentContacts()
        
        let allRecords: [PhoneBookRecord] = details.compactMap { detail in
            guard let contact = contacts.first(where: { $0.id == detail.id }) else {
                return nil
            }
            return PhoneBookRecord(id: detail.id, detail: detail, contact: contact)
        }
        
        await send(.recordsUpdated(allRecords))
        await send(.randomizationCompleted)
    }

}

// MARK: - TCA Dependencies
extension DependencyValues {
    var phoneBookSource: PhoneBookSource {
        get { self[PhoneBookSourceKey.self] }
        set { self[PhoneBookSourceKey.self] = newValue }
    }
}

private enum PhoneBookSourceKey: DependencyKey {
    static let liveValue: PhoneBookSource = {
        let details = [
            PersonDetail(id: "1", name: "Alice"),
            PersonDetail(id: "2", name: "Bob")
        ]
        let contacts = [
            PersonContact(id: "1", phoneNumber: "123-456-7890"),
            PersonContact(id: "2", phoneNumber: "987-654-3210")
        ]
        return PhoneBookSource(personDetails: details, personContacts: contacts)
    }()
}
