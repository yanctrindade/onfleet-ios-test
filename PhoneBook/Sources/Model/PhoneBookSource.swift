import Foundation
import Combine

final class PhoneBookSource {
    
    private let personDetailsSubject: CurrentValueSubject<[PersonDetail], Never>
    private let personContactsSubject: CurrentValueSubject<[PersonContact], Never>
    
    var personDetails: AnyPublisher<[PersonDetail], Never> {
        return self.personDetailsSubject.eraseToAnyPublisher()
    }
    
    var personContacts: AnyPublisher<[PersonContact], Never> {
        return self.personContactsSubject.eraseToAnyPublisher()
    }
    
    init(
        personDetails: [PersonDetail],
        personContacts: [PersonContact]
    ) {
        self.personDetailsSubject = .init(personDetails)
        self.personContactsSubject = .init(personContacts)
    }
    
    func addPerson(
        detail: PersonDetail,
        contact: PersonContact
    ) {
        self.personDetailsSubject.value.append(detail)
        self.personContactsSubject.value.append(contact)
    }
    
}
