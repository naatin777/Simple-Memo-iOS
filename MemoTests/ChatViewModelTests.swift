import Testing
import Foundation
import SwiftData
@testable import Memo

@MainActor
@Suite("Chat ViewModel Tests")
struct ChatViewModelTests {
    private let container: ModelContainer
    private let context: ModelContext
    private let item: Item
    private let sut: ChatViewModel

    init() throws {
        let schema = Schema([
            Item.self,
            ChatMessage.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [config]
        )

        self.container = container
        self.context = container.mainContext

        let item = Item(title: "Test Memo")
        context.insert(item)
        try context.save()

        self.item = item
        self.sut = ChatViewModel(
            modelContext: context,
            item: item
        )
    }

    @Test("When text message is sent, it should be added to messages")
    func testSendText() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        sut.sendText("hello", fixedDate)

        #expect(sut.messages.count == 1)
        #expect(sut.messages.first?.text == "hello")
        #expect(sut.messages.first?.createdAt == fixedDate)
    }

    @Test("When empty text is sent, it should not be added")
    func testSendEmptyText() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        sut.sendText("   ", fixedDate)

        #expect(sut.messages.isEmpty)
    }

    @Test("When text has spaces, it should be trimmed")
    func testSendTextTrimsWhitespaces() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        sut.sendText("  hello  ", fixedDate)

        #expect(sut.messages.first?.text == "hello")
        #expect(sut.messages.first?.createdAt == fixedDate)
    }
    
    @Test("When message is sent, item updatedAt should be updated")
    func testSendTextUpdatesItemUpdatedAt() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        sut.sendText("hello", fixedDate)

        #expect(item.updatedAt == fixedDate)
    }
    
    @Test("When message is sent, it should be persisted in SwiftData")
    func testSendTextPersistsMessage() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        sut.sendText("persisted", fixedDate)

        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [
                SortDescriptor(\ChatMessage.createdAt, order: .forward)
            ]
        )

        let messages = try context.fetch(descriptor)

        #expect(messages.count == 1)
        #expect(messages.first?.text == "persisted")
        #expect(messages.first?.item?.id == item.id)
    }
    
    @Test("When title is updated, item title should be changed")
    func testUpdateTitleChangesItemTitle() {
        sut.updateTitle("New Title")

        #expect(item.title == "New Title")
    }

    @Test("When title has spaces, it should be trimmed")
    func testUpdateTitleTrimsWhitespaces() {
        sut.updateTitle("  New Title  ")

        #expect(item.title == "New Title")
    }

    @Test("When empty title is updated, it should be ignored")
    func testUpdateTitleIgnoresEmptyTitle() {
        let originalTitle = item.title

        sut.updateTitle("   ")

        #expect(item.title == originalTitle)
    }
    
    @Test("When title is updated, item updatedAt should be changed")
    func testUpdateTitleChangesUpdatedAt() {
        let oldUpdatedAt = item.updatedAt

        sut.updateTitle("New Title")

        #expect(item.updatedAt >= oldUpdatedAt)
    }
}
