import Foundation

struct ChatMessageSnapshot: Sendable {
  let id: UUID
  let role: ChatMessageRole
  let text: String
  let createdAt: Date
}
