
struct PersonDetail: Identifiable, Sendable, Equatable {
    
    let id: String
    let name: String
    
}

struct PersonContact: Identifiable, Sendable, Equatable {
    
    let id: String
    let phoneNumber: String
    
}

struct PhoneBookRecord: Identifiable, Sendable, Equatable {
    
    let id: String
    let detail: PersonDetail
    let contact: PersonContact
    
}

struct NewPhoneBookRecord: Identifiable, Sendable {

    let id: String
    let name: String
    let phoneNumber: String

}
