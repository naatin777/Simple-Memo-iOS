import Foundation
import SwiftData
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []

    private let modelContext: ModelContext
    private let item: Item

    init(
        modelContext: ModelContext,
        item: Item
    ) {
        self.modelContext = modelContext
        self.item = item
        fetchMessages()
    }

    func message(for id: ChatMessage.ID) -> ChatMessage? {
        messages.first { $0.id == id }
    }

    func fetchMessages() {
        let itemID = item.id

        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate { message in
                message.item?.id == itemID
            },
            sortBy: [
                SortDescriptor(\ChatMessage.createdAt, order: .forward)
            ]
        )

        do {
            messages = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch messages failed: \(error)")
        }
    }

    func sendText(
        _ text: String,
        _ createdAt: Date = Date()
    ) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            return
        }

        let message = ChatMessage(
            text: trimmedText,
            createdAt: createdAt,
            item: item
        )

        modelContext.insert(message)
        item.updatedAt = createdAt

        do {
            try modelContext.save()
            fetchMessages()
        } catch {
            print("Save message failed: \(error)")
        }
    }
    
    func updateTitle(_ title: String, _ createdAt: Date = Date()) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        item.title = trimmedTitle
        item.updatedAt = createdAt

        do {
            try modelContext.save()
        } catch {
            print("Update title failed: \(error)")
        }
    }
}
