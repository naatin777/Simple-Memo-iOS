import Testing
import SnapshotTesting
import SwiftData
import UIKit
import Foundation
@testable import Memo

@MainActor
@Suite("Memo List UI Tests")
struct MemoListViewControllerTests {
    
    private let container: ModelContainer
    private let context: ModelContext
    private let viewModel: MemoListViewModel
    
    init() throws {
        let schema = Schema([Item.self, ChatMessage.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        self.container = container
        self.context = container.mainContext
        self.viewModel = MemoListViewModel(modelContext: context)
    }
    
    @Test("Visual representation of the list when multiple notes exist")
    func testListViewWithMemos() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        viewModel.addItem(title: "One", updatedAt: fixedDate)
        viewModel.addItem(title: "Two Two", updatedAt: fixedDate)
        viewModel.addItem(title: "Three Three Three", updatedAt: fixedDate)
        
        let viewController = MemoListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        
        assertSnapshot(of: navigationController, as: .image(on: .iPhone13Pro))
    }
    
    @Test("Add memo alert has expected configuration")
    func testAddMemoAlertConfiguration() throws {
        let viewController = MemoListViewController(viewModel: viewModel)
        let alert = viewController.makeAddMemoAlert()

        #expect(alert.title == String(localized: .newMemo))
        #expect(alert.message == String(localized: .enterATitle))
        #expect(alert.textFields?.count == 1)
        #expect(alert.textFields?.first?.placeholder == String(localized: .title))

        let actionTitles = alert.actions.map(\.title)

        #expect(actionTitles.contains(String(localized: .cancel)))
        #expect(actionTitles.contains(String(localized: .add)))
    }
    
    @Test("When memo cell is tapped, ChatViewController is pushed")
    func testTapMemoCellPushesChatViewController() throws {
        viewModel.addItem(title: "Test Memo")

        let listViewController = MemoListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: listViewController)

        listViewController.loadViewIfNeeded()

        let tableView = try #require(findTableView(in: listViewController.view))

        listViewController.tableView(
            tableView,
            didSelectRowAt: IndexPath(row: 0, section: 0)
        )

        #expect(navigationController.topViewController is ChatViewController)
    }
    
    @Test("Delete swipe action is configured")
    func testDeleteSwipeActionIsConfigured() throws {
        viewModel.addItem(title: "Delete Target")

        let listViewController = MemoListViewController(viewModel: viewModel)
        _ = UINavigationController(rootViewController: listViewController)

        listViewController.loadViewIfNeeded()

        let tableView = try #require(findTableView(in: listViewController.view))

        let configuration = listViewController.tableView(
            tableView,
            trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0)
        )

        #expect(configuration != nil)
    }
    
    @Test("When entering editing mode, sort option becomes custom")
    func testEnteringEditingModeUsesCustomSort() throws {
        let listViewController = MemoListViewController(viewModel: viewModel)
        _ = UINavigationController(rootViewController: listViewController)

        listViewController.loadViewIfNeeded()

        listViewController.setEditing(true, animated: false)

        #expect(viewModel.sortOption == .custom)
    }
    
    @Test("When editing mode is enabled, row can be moved")
    func testRowCanMoveWhenEditingModeIsEnabled() throws {
        viewModel.addItem(title: "Move Target")

        let listViewController = MemoListViewController(viewModel: viewModel)
        _ = UINavigationController(rootViewController: listViewController)

        listViewController.loadViewIfNeeded()
        listViewController.setEditing(true, animated: false)

        let tableView = try #require(findTableView(in: listViewController.view))

        let canMove = tableView.dataSource?.tableView?(
            tableView,
            canMoveRowAt: IndexPath(row: 0, section: 0)
        )

        #expect(canMove == true)
    }
    
    @Test("When not editing, row cannot be moved because sort option is not custom")
    func testRowCannotMoveWhenSortOptionIsNotCustom() throws {
        viewModel.addItem(title: "Move Target")

        let listViewController = MemoListViewController(viewModel: viewModel)
        _ = UINavigationController(rootViewController: listViewController)

        listViewController.loadViewIfNeeded()

        let tableView = try #require(findTableView(in: listViewController.view))

        let canMove = tableView.dataSource?.tableView?(
            tableView,
            canMoveRowAt: IndexPath(row: 0, section: 0)
        )

        #expect(canMove == false)
    }
    
    @Test("Sort menu has expected actions")
    func testSortMenuHasExpectedActions() throws {
        let viewController = MemoListViewController(viewModel: viewModel)

        viewController.loadViewIfNeeded()

        let menu = viewController.makeSortMenu()
        
        #expect(menu.children.count == 3)
    }
    
    @Test("Custom order persists after refetch")
    func testCustomOrderPersistsAfterRefetch() throws {
        viewModel.addItem(title: "One")
        viewModel.addItem(title: "Two")
        viewModel.addItem(title: "Three")

        viewModel.sortOption = .custom
        viewModel.moveItem(from: 2, to: 0)

        let anotherViewModel = MemoListViewModel(modelContext: context)
        anotherViewModel.sortOption = .custom

        #expect(anotherViewModel.items.map(\.title) == ["Three", "One", "Two"])
        #expect(anotherViewModel.items.map(\.orderIndex) == [0, 1, 2])
    }
    
    private func findTableView(in view: UIView) -> UITableView? {
        if let tableView = view as? UITableView {
            return tableView
        }

        for subview in view.subviews {
            if let tableView = findTableView(in: subview) {
                return tableView
            }
        }

        return nil
    }
}
