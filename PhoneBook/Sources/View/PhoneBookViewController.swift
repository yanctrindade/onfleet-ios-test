import UIKit
import Fakery
import ComposableArchitecture

class PhoneBookViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var randomizeButton: UIButton!
    
    private let store: PhoneBookStore = Store.phoneBookStore()
    
    private var storeObservationTask: Task<Void, Never>?
    private static let cellIdentifier = "PhoneBookRecordCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: Self.cellIdentifier
        )

        self.tableView.tableHeaderView = self.searchBar
        
        startObservingStore()
        store.send(.viewDidLoad)
    }
    
    deinit {
        storeObservationTask?.cancel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "NewContactSequeID",
              let navigationController = segue.destination as? UINavigationController,
              let destination = navigationController.viewControllers.first as? CreatePhoneBookRecordViewController else {
            return
        }
        destination.store = self.store
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
        store.send(.searchTextChanged(searchText))
    }
    
}

// MARK: - Actions

extension PhoneBookViewController {
    
    @IBAction
    func randomizeButtonTapped(_ sender: Any) {
        store.send(.randomizeButtonTapped)
    }
    
}

private extension PhoneBookViewController {

    func startObservingStore() {
        storeObservationTask = Task { @MainActor in
            for await state in store.publisher.values {
                handleStateChange(state)
            }
        }
    }
    
    func handleStateChange(_ state: PhoneBookFeature.State) {
        self.randomizeButton.isEnabled = !state.isRandomizing

        self.tableView.reloadData()

        if searchBar.text != state.searchText {
            searchBar.text = state.searchText
        }
    }
    
}
