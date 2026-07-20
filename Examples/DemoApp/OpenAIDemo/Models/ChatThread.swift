import Foundation
import SwiftData

@Model
final class ChatThread {
  @Attribute(.unique) var id: UUID
  var title: String
  var modelID: String
  var createdAt: Date
  var updatedAt: Date
  @Relationship(deleteRule: .cascade, inverse: \ChatMessage.thread)
  var messages: [ChatMessage] = []

  init(
    id: UUID = UUID(),
    title: String = "New conversation",
    modelID: String,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = id
    self.title = title
    self.modelID = modelID
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
