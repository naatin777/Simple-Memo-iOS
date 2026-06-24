import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var title: String
    var updatedAt: Date
    var orderIndex: Int
    
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.item)
    var messages: [ChatMessage]
    
    init(id: UUID = UUID(), title: String, updatedAt: Date = Date(), orderIndex: Int = 0, messages: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.updatedAt = updatedAt
        self.orderIndex = orderIndex
        self.messages = messages
    }
}
