import Foundation

actor PhoneBookSource {
    
    private var _personDetails: [PersonDetail]
    private var _personContacts: [PersonContact]
    
    // Store continuations to notify subscribers of changes
    private var _detailsContinuations: [UUID: AsyncStream<[PersonDetail]>.Continuation] = [:]
    private var _contactsContinuations: [UUID: AsyncStream<[PersonContact]>.Continuation] = [:]
    
    init(
        personDetails: [PersonDetail],
        personContacts: [PersonContact]
    ) {
        self._personDetails = personDetails
        self._personContacts = personContacts
    }
    
    var personDetailsSequence: AsyncStream<[PersonDetail]> {
        AsyncStream { continuation in
            // Send current value immediately
            continuation.yield(_personDetails)
            
            // Store continuation for future updates with unique ID
            let id = UUID()
            _detailsContinuations[id] = continuation
            
            // Clean up when cancelled
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.removeDetailsContinuation(id)
                }
            }
        }
    }

    var personContactsSequence: AsyncStream<[PersonContact]> {
        AsyncStream { continuation in
            // Send current value immediately  
            continuation.yield(_personContacts)
            
            // Store continuation for future updates with unique ID
            let id = UUID()
            _contactsContinuations[id] = continuation
            
            // Clean up when cancelled
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.removeContactsContinuation(id)
                }
            }
        }
    }
    
    func addPerson(
        detail: PersonDetail,
        contact: PersonContact
    ) {
        _personDetails.append(detail)
        _personContacts.append(contact)
        
        // Notify all subscribers of the changes
        notifyDetailsSubscribers()
        notifyContactsSubscribers()
    }
    
    func getCurrentDetails() -> [PersonDetail] {
        return _personDetails
    }
    
    func getCurrentContacts() -> [PersonContact] {
        return _personContacts
    }
    
    // MARK: - Private Helper Methods
    
    private func removeDetailsContinuation(_ id: UUID) {
        _detailsContinuations.removeValue(forKey: id)
    }
    
    private func removeContactsContinuation(_ id: UUID) {
        _contactsContinuations.removeValue(forKey: id)
    }
    
    private func notifyDetailsSubscribers() {
        for continuation in _detailsContinuations.values {
            continuation.yield(_personDetails)
        }
    }
    
    private func notifyContactsSubscribers() {
        for continuation in _contactsContinuations.values {
            continuation.yield(_personContacts)
        }
    }
    
}
