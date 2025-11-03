import Foundation

final class PhoneBookManager {
    
    private var records: [PhoneBookRecord] = []
    private var _recordsStream: AsyncStream<[PhoneBookRecord]>?
    private var _recordsContinuation: AsyncStream<[PhoneBookRecord]>.Continuation?
    let source: PhoneBookSource
    private var observationTask: Task<Void, Never>?
    
    // Computed property to safely access records from main actor
    @MainActor 
    var currentRecords: [PhoneBookRecord] {
        return records
    }
    
    var recordsSequence: AsyncStream<[PhoneBookRecord]> {
        if let stream = _recordsStream {
            return stream
        }
        
        let (stream, continuation) = AsyncStream<[PhoneBookRecord]>.makeStream()
        _recordsStream = stream
        _recordsContinuation = continuation
        
        continuation.yield(records)
        
        return stream
    }
    
    init(source: PhoneBookSource) {
        self.source = source
        self.startObservingSource()
    }
    
    deinit {
        observationTask?.cancel()
    }
    
    func addRecord(from entry: NewPhoneBookRecord) async {
        await self.source.addPerson(
            detail: .init(
                id: entry.id,
                name: entry.name
            ),
            contact: .init(
                id: entry.id,
                phoneNumber: entry.phoneNumber
            )
        )
    }
    
}

private extension PhoneBookManager {
    
    func startObservingSource() {
        observationTask = Task {
            await observeDataSources()
        }
    }
    
    func observeDataSources() async {
        // Since we need to combine two AsyncSequences, we'll use a different approach
        // We'll observe both sources and manually combine the data
        await withTaskGroup(of: Void.self) { group in
            
            group.addTask {
                for await _ in await self.source.personDetailsSequence {
                    await self.updateRecords()
                }
            }
            
            group.addTask {
                for await _ in await self.source.personContactsSequence {
                    await self.updateRecords()
                }
            }
        }
    }
    
    func updateRecords() async {
        let details = await source.getCurrentDetails()
        let contacts = await source.getCurrentContacts()
        
        let combinedRecords: [PhoneBookRecord] = details.compactMap { detail in
            guard let contact = contacts.first(where: { $0.id == detail.id }) else {
                return nil
            }
            return PhoneBookRecord(
                id: detail.id,
                detail: detail,
                contact: contact
            )
        }

        await MainActor.run {
            self.records = combinedRecords
            self._recordsContinuation?.yield(combinedRecords)
        }
    }
    
}

struct PhoneBookManagerFactory {
    
    static func makeDefaultManager() -> PhoneBookManager {
        let details = [
            PersonDetail(
                id: "1",
                name: "Alice"
            ),
            PersonDetail(
                id: "2",
                name: "Bob"
            )
        ]
        let contacts = [
            PersonContact(
                id: "1",
                phoneNumber: "123-456-7890"
            ),
            PersonContact(
                id: "2",
                phoneNumber: "987-654-3210"
            )
        ]
        let source = PhoneBookSource(
            personDetails: details,
            personContacts: contacts
        )
        return .init(source: source)
    }
    
}
