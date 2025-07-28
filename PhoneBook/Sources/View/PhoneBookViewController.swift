import UIKit
import Combine
import Fakery

class PhoneBookViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var randomizeButton: UIButton!
    
    var manager: PhoneBookManager!
    
    @Published
    private var searchText: String?
    private var filteredRecords: [PhoneBookRecord] = []
    private var cancellables = Set<AnyCancellable>()
    private static let cellIdentifier = "PhoneBookRecordCell"
    private let managerQueue = DispatchQueue(label: "com.phonebook.manager", qos: .userInitiated)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.manager == nil {
            self.manager = PhoneBookManagerFactory.makeDefaultManager()
        }
        self.tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: Self.cellIdentifier
        )
        self.tableView.tableHeaderView = self.searchBar
        Publishers.CombineLatest(
            self.manager.$records,
            self.$searchText
        )
        .map({ records, searchText in
            guard let searchText,
                  !searchText.isEmpty else {
                return records
            }
            return records.filter {
                $0.detail.name.localizedCaseInsensitiveContains(searchText) ||
                $0.contact.phoneNumber.localizedCaseInsensitiveContains(searchText)
            }
        })
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] filtered in
            self?.filteredRecords = filtered
            self?.tableView.reloadData()
        })
        .store(in: &self.cancellables)
        // Additional setup if needed
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "NewContactSequeID",
              let navigationController = segue.destination as? UINavigationController,
              let destination = navigationController.viewControllers.first as? CreatePhoneBookRecordViewController else {
            return
        }
        destination.manager = self.manager
    }
    
}

// MARK: - UITableViewDataSource

extension PhoneBookViewController: UITableViewDataSource {
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return self.filteredRecords.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellIdentifier,
            for: indexPath
        )
        let record = self.filteredRecords[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = record.detail.name
        content.secondaryText = record.contact.phoneNumber
        cell.contentConfiguration = content
        return cell
    }
    
}

// MARK: - UISearchBarDelegate

extension PhoneBookViewController: UISearchBarDelegate {
    
    func searchBar(
        _ searchBar: UISearchBar,
        textDidChange searchText: String
    ) {
        self.searchText = searchText
    }
    
}

// MARK: - Actions

extension PhoneBookViewController {
    
    @IBAction
    func randomizeButtonTapped(_ sender: Any) {
        self.randomizeButton.isEnabled = false
        self.addRandomizedRecords(completion: { [weak self] in
            self?.randomizeButton.isEnabled = true
        })
    }
    
}

private extension PhoneBookViewController {
    
    func makePhoneBookRecord(using faker: Faker) -> NewPhoneBookRecord {
        return .init(
            id: .init(faker.number.randomInt()),
            name: faker.name.name(),
            phoneNumber: faker.phoneNumber.phoneNumber()
        )
    }
    
    func addRandomizedRecords(completion: @escaping () -> Void) {
        let faker = Faker()
        let records = (0..<5).map({ _ in self.makePhoneBookRecord(using: faker) })
        let group = DispatchGroup()
        
        DispatchQueue.concurrentPerform(
            iterations: 4,
            execute: { [managerQueue, manager] index in
                group.enter()
                let startIndex = index * (records.count / 4)
                let endIndex = (index == 3) ? records.count : (index + 1) * (records.count / 4)
                
                for i in startIndex..<endIndex {
                    managerQueue.sync(execute: {
                        manager?.addRecord(from: records[i])
                    })
                }
                group.leave()
            }
        )
        group.notify(
            queue: .main,
            execute: { completion() }
        )
    }
    
}
