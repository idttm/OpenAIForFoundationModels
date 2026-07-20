import Foundation
import SwiftData

@Model
final class ChatMessage {
  @Attribute(.unique) var id: UUID
  var roleRawValue: String
  var text: String
  var createdAt: Date
  var responseID: String?
  var inputTokens: Int?
  var outputTokens: Int?
  var thread: ChatThread?

  init(
    id: UUID = UUID(),
    role: ChatMessageRole,
    text: String,
    createdAt: Date = .now,
    responseID: String? = nil,
    inputTokens: Int? = nil,
    outputTokens: Int? = nil,
    thread: ChatThread? = nil
  ) {
    self.id = id
    self.roleRawValue = role.rawValue
    self.text = text
    self.createdAt = createdAt
    self.responseID = responseID
    self.inputTokens = inputTokens
    self.outputTokens = outputTokens
    self.thread = thread
  }

  var role: ChatMessageRole {
    get { ChatMessageRole(rawValue: roleRawValue) ?? .assistant }
    set { roleRawValue = newValue.rawValue }
  }
}
