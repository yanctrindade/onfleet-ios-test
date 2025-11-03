import UIKit
import Fakery

class PhoneBookViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var randomizeButton: UIButton!
    
    // PHASE 1: Keep existing manager + Add Redux store
    var manager: PhoneBookManager!
    private let store = Store(initialState: PhoneBookState.initial, reducer: PhoneBookReducer())
    
    private var observationTask: Task<Void, Never>?
    private var storeObservationTask: Task<Void, Never>?
    private static let cellIdentifier = "PhoneBookRecordCell"
    
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
        
        // PHASE 1: Start both old and new observation systems
        startObservingRecords()  // Existing AsyncSequence observation
        startObservingStore()    // New Redux store observation
        
        // Send initial Redux action
        store.send(.viewDidLoad)
    }
    
    deinit {
        observationTask?.cancel()
        storeObservationTask?.cancel()
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
        return store.state.filteredRecords.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellIdentifier,
            for: indexPath
        )
        let record = store.state.filteredRecords[indexPath.row]
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
        // PHASE 1: Dispatch Redux action instead of direct state manipulation
        store.send(.searchTextChanged(searchText))
        
        // Keep old behavior for compatibility during Phase 1
        updateFilteredRecords()
    }
    
}

// MARK: - Actions

extension PhoneBookViewController {
    
    @IBAction
    func randomizeButtonTapped(_ sender: Any) {
        // PHASE 1: Dispatch Redux actions
        store.send(.randomizeButtonTapped)
        
        Task { @MainActor in
            await self.addRandomizedRecords()
            store.send(.randomizationCompleted)
        }
    }
    
}

private extension PhoneBookViewController {
    
    // PHASE 1: Keep existing AsyncSequence observation
    func startObservingRecords() {
        observationTask = Task { @MainActor in
            for await records in manager.recordsSequence {
                // Bridge to Redux store
                store.send(.recordsUpdated(records))
                await updateFilteredRecords(with: records)
            }
        }
    }
    
    // PHASE 1: Add Redux store observation  
    func startObservingStore() {
        storeObservationTask = Task { @MainActor in
            // Observe store state changes
            for await state in store.$state.values {
                handleStateChange(state)
            }
        }
    }
    
    func handleStateChange(_ state: PhoneBookState) {
        // Update UI based on Redux state
        self.randomizeButton.isEnabled = !state.isRandomizing
        
        // Reload table view with Redux filtered records
        self.tableView.reloadData()
        
        // Update search bar if needed
        if searchBar.text != state.searchText {
            searchBar.text = state.searchText
        }
    }
    
    func updateFilteredRecords(with records: [PhoneBookRecord]? = nil) async {
        let currentRecords = records ?? manager.currentRecords
        
        let filtered: [PhoneBookRecord]
        if let searchText = store.state.searchText, !searchText.isEmpty {
            filtered = currentRecords.filter {
                $0.detail.name.localizedCaseInsensitiveContains(searchText) ||
                $0.contact.phoneNumber.localizedCaseInsensitiveContains(searchText)
            }
        } else {
            filtered = currentRecords
        }
        
        store.send(.recordsFiltered(filtered))
    }
    
    func updateFilteredRecords() {
        Task { @MainActor in
            await updateFilteredRecords()
        }
    }
    
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
