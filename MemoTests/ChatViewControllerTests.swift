import Testing
import SwiftData
import UIKit
import SnapshotTesting
@testable import Memo

@MainActor
@Suite("Chat ViewController Tests")
struct ChatViewControllerTests {
    private let container: ModelContainer
    private let context: ModelContext
    private let item: Item
    private let sut: ChatViewModel

    init() throws {
        let schema = Schema([Item.self, ChatMessage.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        self.container = container
        self.context = container.mainContext

        let item = Item(title: "Test Memo")
        context.insert(item)
        try context.save()

        self.item = item
        self.sut = ChatViewModel(modelContext: context, item: item)
    }

    @Test("Chat view contains table view")
    func testChatViewContainsTableView() throws {
        let viewController = ChatViewController(item: item, modelContext: context)

        viewController.loadViewIfNeeded()

        let tableView = findSubview(in: viewController.view, ofType: UITableView.self)

        #expect(tableView != nil)
    }

    @Test("Chat view contains input text view")
    func testChatViewContainsInputTextView() throws {
        let viewController = ChatViewController(
            item: item,
            modelContext: context
        )

        viewController.loadViewIfNeeded()

        let textView = findSubview(
            in: viewController.view,
            ofType: UITextView.self
        )

        #expect(textView != nil)
    }

    @Test("Chat view contains send button")
    func testChatViewContainsSendButton() throws {
        let viewController = ChatViewController(item: item, modelContext: context)

        viewController.loadViewIfNeeded()

        let button = findSubview(in: viewController.view, ofType: UIButton.self)

        #expect(button != nil)
        #expect(button?.title(for: .normal) == String(localized: .send))
    }
    
    @Test("Visual representation of chat view")
    func testChatViewSnapshot() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        
        let chatViewModel = ChatViewModel(modelContext: context, item: item)
        chatViewModel.sendText("Hello", fixedDate)
        chatViewModel.sendText("This is a test message", fixedDate)
        chatViewModel.sendText("Longer message to check how the cell looks in the chat table view.", fixedDate)

        let viewController = ChatViewController(
            item: item,
            viewModel: chatViewModel
        )
        let navigationController = UINavigationController(rootViewController: viewController)

        assertSnapshot(
            of: navigationController,
            as: .image(on: .iPhone13Pro)
        )
    }
    
    @Test("Chat input text view shows placeholder initially")
    func testChatInputTextViewShowsPlaceholderInitially() throws {
        let viewController = ChatViewController(
            item: item,
            modelContext: context
        )

        viewController.loadViewIfNeeded()

        let placeholderLabel = findSubview(
            in: viewController.view,
            ofType: UILabel.self
        )

        #expect(placeholderLabel?.text == String(localized: .message))
        #expect(placeholderLabel?.isHidden == false)
    }
    
    @Test("Chat view has edit title button")
    func testChatViewHasEditTitleButton() throws {
        let viewController = ChatViewController(
            item: item,
            modelContext: context
        )

        viewController.loadViewIfNeeded()

        #expect(viewController.navigationItem.rightBarButtonItem != nil)
    }
    
    @Test("Edit title alert has expected configuration")
    func testEditTitleAlertHasExpectedConfiguration() throws {
        let viewController = ChatViewController(
            item: item,
            modelContext: context
        )

        viewController.loadViewIfNeeded()

        let alert = viewController.makeEditTitleAlert()
        
        #expect(alert.title == String(localized: .editTitle))
        #expect(alert.textFields?.count == 1)
        #expect(alert.actions.map(\.title) == [String(localized: .cancel), String(localized: .save)])
    }
    
    private func findSubview<T: UIView>(
        in view: UIView,
        ofType type: T.Type
    ) -> T? {
        if let targetView = view as? T {
            return targetView
        }

        for subview in view.subviews {
            if let targetView = findSubview(in: subview, ofType: type) {
                return targetView
            }
        }

        return nil
    }
}
