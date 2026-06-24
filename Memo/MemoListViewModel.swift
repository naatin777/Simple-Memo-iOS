import Foundation
import SwiftData
import Combine

enum SortOption: Equatable {
    case title
    case updatedAt
    case custom
}

@MainActor
class MemoListViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    var modelContext: ModelContext
    
    var sortOption: SortOption = .updatedAt {
        didSet {
            fetchItems()
        }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchItems()
    }
    
    func item(for id: Item.ID) -> Item? {
        items.first { $0.id == id }
    }
    
    func fetchItems() {
        let descriptor: FetchDescriptor<Item> = switch sortOption {
        case .title:
            FetchDescriptor<Item>(sortBy: [SortDescriptor(\Item.title, order: .forward)])
        case .updatedAt:
            FetchDescriptor<Item>(sortBy: [SortDescriptor(\Item.updatedAt, order: .reverse)])
        case .custom:
            FetchDescriptor<Item>(sortBy: [SortDescriptor(\Item.orderIndex, order: .forward)])
        }
        
        do {
            items = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed: \(error)")
        }
    }
    
    func addItem(title: String, updatedAt: Date = Date()) {
        let newIndex = items.map(\.orderIndex).max().map { $0 + 1 } ?? 0
        let newItem = Item(title: title, updatedAt: updatedAt, orderIndex: newIndex)
        
        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
            fetchItems()
        } catch {
            print("Save failed: \(error)")
        }
    }
    
    func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
        guard sortOption == .custom else {
            return
        }

        guard items.indices.contains(sourceIndex) else {
            return
        }

        guard items.indices.contains(destinationIndex) else {
            return
        }

        guard sourceIndex != destinationIndex else {
            return
        }

        var rearrangedItems = items
        let movedItem = rearrangedItems.remove(at: sourceIndex)

        let insertionIndex = min(destinationIndex, rearrangedItems.count)

        rearrangedItems.insert(movedItem, at: insertionIndex)

        for (index, item) in rearrangedItems.enumerated() {
            item.orderIndex = index
        }

        do {
            try modelContext.save()
            items = rearrangedItems
        } catch {
            print("Order update failed: \(error)")
        }
    }
    
    func updateOrder(itemIDs: [Item.ID]) {
        guard sortOption == .custom else {
            return
        }

        let itemByID = Dictionary(
            uniqueKeysWithValues: items.map { ($0.id, $0) }
        )

        let reorderedItems = itemIDs.compactMap { itemByID[$0] }

        guard reorderedItems.count == itemIDs.count else {
            return
        }

        for (index, item) in reorderedItems.enumerated() {
            item.orderIndex = index
        }

        do {
            try modelContext.save()
            items = reorderedItems
        } catch {
            print("Order update failed: \(error)")
        }
    }
    
    func deleteItem(id: Item.ID) {
        guard let item = item(for: id) else { return }
        
        modelContext.delete(item)
        
        do {
            try modelContext.save()
            fetchItems()
        } catch {
            print("Delete failed: \(error)")
        }
    }
}
