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
        
        Task { @MainActor in
            await self.addRandomizedRecords()
            self.randomizeButton.isEnabled = true
        }
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
    
    func addRandomizedRecords() async {
        let faker = Faker()
        let records = (0..<100).map({ _ in self.makePhoneBookRecord(using: faker) })

        // Maintain the threaded nature using TaskGroup to simulate 
        // multi-threaded access to a critical area (the manager)
        await withTaskGroup(of: Void.self) { group in
            let numberOfThreads = 4
            let recordsPerThread = records.count / numberOfThreads
            
            for threadIndex in 0..<numberOfThreads {
                group.addTask { [manager] in
                    let startIndex = threadIndex * recordsPerThread
                    let endIndex = (threadIndex == numberOfThreads - 1) 
                        ? records.count 
                        : (threadIndex + 1) * recordsPerThread
                    
                    // Each task processes its portion of records
                    // This simulates concurrent access to the critical area (manager)
                    for i in startIndex..<endIndex {
                        await manager?.addRecord(from: records[i])
                    }
                }
            }
            
            // All tasks complete before continuing
        }
    }
    
}
