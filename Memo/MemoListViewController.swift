import UIKit
import SwiftData
import Combine

nonisolated enum MemoListSection: Hashable, Sendable {
    case main
}

@MainActor
final class MemoListViewController: UIViewController {
    private typealias DataSource = MemoListDataSource
    private typealias Snapshot = NSDiffableDataSourceSnapshot<MemoListSection, Item.ID>
    
    private let viewModel: MemoListViewModel
    private let tableView = UITableView()
    private var dataSource: DataSource?
    private var cancellables = Set<AnyCancellable>()
    private var sortButton: UIBarButtonItem?
    
    private var isReordering = false
    
    init(viewModel: MemoListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(localized: .memoList)
        view.backgroundColor = .systemBackground
        
        setupTableView()
        configureDataSource()
        setupNavigationBar()
        observeViewModel()
        updateUI(animated: false)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.fetchItems()
    }
}

extension MemoListViewController {
    func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.accessibilityIdentifier = "memoList.tableView"
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func configureDataSource() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        dataSource = DataSource(tableView: tableView) { [weak self] tableView, indexPath, itemID in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "cell",
                for: indexPath
            )

            guard let item = self?.viewModel.item(for: itemID) else {
                return cell
            }

            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.secondaryText = item.updatedAt.formatted(
                date: .abbreviated,
                time: .shortened
            )

            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator

            return cell
        }
        
        dataSource?.canMoveItem = { [weak self] _ in
            guard let self else { return false }
            return self.viewModel.sortOption == .custom
        }
        
        dataSource?.moveItem = { [weak self] sourceIndexPath, destinationIndexPath in
            guard let self else { return }

            self.isReordering = true

            self.viewModel.moveItem(
                from: sourceIndexPath.row,
                to: destinationIndexPath.row
            )

            self.isReordering = false

            self.updateUI(animated: false)
        }
    }
    
    func setupNavigationBar() {
        let addAction = UIAction { [weak self] _ in
            guard let self else { return }
            present(makeAddMemoAlert(), animated: true)
        }

        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            menu: makeSortMenu()
        )
        sortButton.accessibilityIdentifier = "memoList.sortButton"

        self.sortButton = sortButton
        
        let addButton = UIBarButtonItem(
            systemItem: .add,
            primaryAction: addAction
        )
        addButton.accessibilityIdentifier = "memoList.addButton"
        
        navigationItem.rightBarButtonItems = [
            addButton,
            sortButton
        ]
    
        let editAction = UIAction { [weak self] _ in
            guard let self else { return }

            setEditing(!isEditing, animated: true)
        }
        
        sortButton.accessibilityIdentifier = "memoList.sortButton"

        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "memoList.editButton"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            primaryAction: editAction
        )
    }
    
    func setSortOption(_ sortOption: SortOption) {
        viewModel.sortOption = sortOption
        sortButton?.menu = makeSortMenu()
    }
    
    func makeSortMenu() -> UIMenu {
        let updatedAtAction = UIAction(
            title: String(localized: .newest),
            image: UIImage(systemName: "clock"),
            state: viewModel.sortOption == .updatedAt ? .on : .off
        ) { [weak self] _ in
            self?.setSortOption(.updatedAt)
        }

        let titleAction = UIAction(
            title: String(localized: .name),
            image: UIImage(systemName: "textformat"),
            state: viewModel.sortOption == .title ? .on : .off
        ) { [weak self] _ in
            self?.setSortOption(.title)
        }

        let customAction = UIAction(
            title: String(localized: .manual),
            image: UIImage(systemName: "line.3.horizontal"),
            state: viewModel.sortOption == .custom ? .on : .off
        ) { [weak self] _ in
            self?.setSortOption(.custom)
        }

        return UIMenu(
            title: String(localized: .sort),
            children: [
                updatedAtAction,
                titleAction,
                customAction
            ]
        )
    }
}

private extension MemoListViewController {
    func observeViewModel() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI(animated: true)
            }
            .store(in: &cancellables)
    }
}

private extension MemoListViewController {
    func updateUI(animated: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])

        let itemIDs = viewModel.items.map(\.id)
        snapshot.appendItems(itemIDs, toSection: .main)

        dataSource?.apply(snapshot, animatingDifferences: animated)
    }
}

extension MemoListViewController {
    func makeAddMemoAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: String(localized: .newMemo),
            message: String(localized: .enterATitle),
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = String(localized: .title)
        }

        let cancelAction = UIAlertAction(
            title: String(localized: .cancel),
            style: .cancel
        )

        let addAction = UIAlertAction(
            title: String(localized: .add),
            style: .default
        ) { [weak self, weak alert] _ in
            guard let title = alert?.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !title.isEmpty
            else {
                return
            }

            self?.viewModel.addItem(title: title)
        }

        alert.addAction(cancelAction)
        alert.addAction(addAction)

        return alert
    }
}

extension MemoListViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard
            let itemID = dataSource?.itemIdentifier(for: indexPath),
            let item = viewModel.item(for: itemID)
        else {
            return
        }
        
        let chatViewController = ChatViewController(item: item, modelContext: viewModel.modelContext)
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: String(localized: .delete)
        ) { [weak self] _, _, completion in
            guard
                let self,
                let itemID = self.dataSource?.itemIdentifier(for: indexPath)
            else {
                completion(false)
                return
            }
            
            self.viewModel.deleteItem(id: itemID)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
