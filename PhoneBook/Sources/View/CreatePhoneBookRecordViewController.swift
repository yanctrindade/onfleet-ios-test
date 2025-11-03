import UIKit
import ComposableArchitecture

class CreatePhoneBookRecordViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var idTextField: UITextField!
    
    var onCreate: ((NewPhoneBookRecord) -> Void)?
    var store: PhoneBookStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isModalInPresentation = self.hasAnyContentFilledIn()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isModalInPresentation = self.hasAnyContentFilledIn()
    }
    
}

private extension CreatePhoneBookRecordViewController {
    
    @IBAction
    func saveButtonTapped(_ sender: Any) {
        guard
            let id = self.idTextField.text,
            !id.isEmpty,
            let name = self.nameTextField.text,
            !name.isEmpty,
            let phoneNumber = self.phoneNumberTextField.text,
            !phoneNumber.isEmpty
        else {
            let alert = UIAlertController(
                title: "Missing Information",
                message: "Please enter an ID, name, and phone number.",
                preferredStyle: .alert
            )
            alert.addAction(.init(
                title: "OK",
                style: .default
            ))
            self.present(
                alert,
                animated: true
            )
            return
        }
        let newRecord = NewPhoneBookRecord(
            id: id,
            name: name,
            phoneNumber: phoneNumber
        )
        
        store.send(.addRecord(newRecord))
        
        self.onCreate?(newRecord)
        self.dismiss(animated: true)
    }
    
    @IBAction
    func cancelButtonTapped(_ sender: Any) {
        if self.hasAnyContentFilledIn() {
            let alert = UIAlertController(
                title: "Discard Changes?",
                message: "You have unsaved changes. Are you sure you want to close?",
                preferredStyle: .alert
            )
            alert.addAction(.init(
                title: "Cancel",
                style: .cancel
            ))
            alert.addAction(.init(
                title: "Discard",
                style: .destructive,
                handler: { [weak self] _ in
                    self?.dismiss(animated: true)
                }
            ))
            self.present(
                alert,
                animated: true
            )
        } else {
            self.dismiss(animated: true)
        }
    }
    
    func hasAnyContentFilledIn() -> Bool {
        return [
            self.idTextField.text,
            self.nameTextField.text,
            self.phoneNumberTextField.text
        ]
            .contains(where: { !($0 ?? "").isEmpty })
    }
    
}
