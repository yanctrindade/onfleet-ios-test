import Foundation
import Combine

final class PhoneBookManager: ObservableObject {
    
    @Published var records: [PhoneBookRecord] = []
    let source: PhoneBookSource
    private var cancellables = Set<AnyCancellable>()
    
    init(source: PhoneBookSource) {
        self.source = source
        self.subscribeToSource()
    }
    // Add methods for managing records as needed
    
    func addRecord(from entry: NewPhoneBookRecord) {
        self.source.addPerson(
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
    
    func subscribeToSource() {
        Publishers.CombineLatest(
            self.source.personDetails,
            self.source.personContacts
        )
        .map({ details, contacts in
            return details.compactMap({ detail in
                guard let contact = contacts.first(where: { $0.id == detail.id }) else {
                    return nil
                }
                return PhoneBookRecord(
                    id: detail.id,
                    detail: detail,
                    contact: contact
                )
            })
        })
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] records in
            self?.records = records
        })
        .store(in: &self.cancellables)
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
