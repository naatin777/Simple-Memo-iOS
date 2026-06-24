import Testing
import SwiftData
import Foundation
@testable import Memo

@MainActor
@Suite("Logic test of Memo List")
struct MemoListViewModelTests {
    private var container: ModelContainer
    private var context: ModelContext
    private var sut: MemoListViewModel
    
    init() throws {
        let schema: Schema = Schema([Item.self, ChatMessage.self])
        let config: ModelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container: ModelContainer = try ModelContainer(for: schema, configurations: [config])
        
        self.container = container
        self.context = container.mainContext
        self.sut = MemoListViewModel(modelContext: context)
    }
    
    @Test("When memo is added, it should be reflected in items")
    func testAddItem() throws {
        sut.addItem(title: "test memo")
        #expect(sut.items.count == 1)
        #expect(sut.items.first?.title == "test memo")
        #expect(sut.items.first?.orderIndex == 0)
    }
    
    @Test("When multiple memos are added, orderIndex should increase")
    func testAddMultipleItems() throws {
        sut.addItem(title: "one")
        sut.addItem(title: "two")
        sut.addItem(title: "three")
        
        #expect(sut.items.count == 3)
        
        let orderIndexes: [Int] = sut.items.map(\.orderIndex)
        
        #expect(orderIndexes.contains(0))
        #expect(orderIndexes.contains(1))
        #expect(orderIndexes.contains(2))
    }
    
    @Test("When item exists, item(for:) should return it")
    func testItemForID() throws {
        sut.addItem(title: "test memo")
        
        let id: UUID = try #require(sut.items.first?.id)
        let item: Item? = sut.item(for: id)
        
        #expect(item?.title == "test memo")
    }
    
    @Test("When item does not exist, item(for:) should return nil")
    func testItemForUnknownID() throws {
        let item: Item? = sut.item(for: UUID())
        
        #expect(item == nil)
    }
    
    @Test("When user drag and drop, order and index are collect written")
    func testMoveItem() throws {
        sut.sortOption = .custom
        
        sut.addItem(title: "one")
        sut.addItem(title: "two")
        sut.addItem(title: "three")
        
        sut.moveItem(from: 1, to: 0)
        
        #expect(sut.items[0].title == "two")
        #expect(sut.items[0].orderIndex == 0)
        
        #expect(sut.items[1].title == "one")
        #expect(sut.items[1].orderIndex == 1)
        
        #expect(sut.items[2].title == "three")
        #expect(sut.items[2].orderIndex == 2)
    }
    
    @Test("When sort option is title, items should be sorted by title")
    func testSortByTitle() throws {
        sut.addItem(title: "Charlie")
        sut.addItem(title: "Alice")
        sut.addItem(title: "Bob")

        sut.sortOption = .title

        #expect(sut.items.map(\.title) == ["Alice", "Bob", "Charlie"])
    }
    
    @Test("When sort option is custom, items should be sorted by orderIndex")
    func testSortByCustomOrder() throws {
        sut.sortOption = .custom

        sut.addItem(title: "one")
        sut.addItem(title: "two")
        sut.addItem(title: "three")

        sut.moveItem(from: 2, to: 0)

        #expect(sut.items.map(\.title) == ["three", "one", "two"])
        #expect(sut.items.map(\.orderIndex) == [0, 1, 2])
    }
    
    @Test("When item is deleted, it should be removed from items")
    func testDeleteItem() throws {
        sut.addItem(title: "delete target")

        let id: UUID = try #require(sut.items.first?.id)

        sut.deleteItem(id: id)

        #expect(sut.items.isEmpty)
    }
    
    @Test("When one item is deleted, other items should remain")
    func testDeleteOneItemKeepsOthers() throws {
        sut.addItem(title: "one")
        sut.addItem(title: "two")

        let target: Item = try #require(sut.items.first { $0.title == "one" })
        
        sut.deleteItem(id: target.id)

        #expect(sut.items.count == 1)
        #expect(sut.items.first?.title == "two")
    }
    
    @Test("When item IDs are reordered, orderIndex should be updated")
    func testUpdateOrder() throws {
        sut.sortOption = .custom

        sut.addItem(title: "one")
        sut.addItem(title: "two")
        sut.addItem(title: "three")

        let one: Item = try #require(sut.items.first { $0.title == "one" })
        let two: Item = try #require(sut.items.first { $0.title == "two" })
        let three: Item = try #require(sut.items.first { $0.title == "three" })

        sut.updateOrder(itemIDs: [
            three.id,
            one.id,
            two.id
        ])

        #expect(sut.items.map(\.title) == ["three", "one", "two"])
        #expect(sut.items.map(\.orderIndex) == [0, 1, 2])
    }
    
    @Test("When item is moved, orderIndex should be updated")
    func testMoveItemUpdatesOrderIndex() throws {
        sut.sortOption = .custom

        sut.addItem(title: "one")
        sut.addItem(title: "two")
        sut.addItem(title: "three")

        sut.moveItem(from: 2, to: 0)

        #expect(sut.items.map(\.title) == ["three", "one", "two"])
        #expect(sut.items.map(\.orderIndex) == [0, 1, 2])
    }
}
