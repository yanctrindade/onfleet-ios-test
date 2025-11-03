import Foundation

actor PhoneBookSource {
    
    private var _personDetails: [PersonDetail]
    private var _personContacts: [PersonContact]
    
    init(
        personDetails: [PersonDetail],
        personContacts: [PersonContact]
    ) {
        self._personDetails = personDetails
        self._personContacts = personContacts
    }
    
    var personDetailsSequence: AsyncStream<[PersonDetail]> {
        AsyncStream { continuation in
            continuation.yield(_personDetails)
            // TODO: store continuations and notify on changes
        }
    }

    var personContactsSequence: AsyncStream<[PersonContact]> {
        AsyncStream { continuation in
            continuation.yield(_personContacts)
            // TODO: store continuations and notify on changes
        }
    }
    
    func addPerson(
        detail: PersonDetail,
        contact: PersonContact
    ) {
        _personDetails.append(detail)
        _personContacts.append(contact)
    }
    
    func getCurrentDetails() -> [PersonDetail] {
        return _personDetails
    }
    
    func getCurrentContacts() -> [PersonContact] {
        return _personContacts
    }
    
}
