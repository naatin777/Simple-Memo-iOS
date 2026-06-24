import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date
    var item: Item?

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        item: Item? = nil
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.item = item
    }
}
