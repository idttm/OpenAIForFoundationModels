import Foundation
import SwiftData
import SwiftUI

struct ChatThreadDestination: View {
  @Query private var threads: [ChatThread]

  init(threadID: UUID) {
    _threads = Query(
      filter: #Predicate<ChatThread> { $0.id == threadID }
    )
  }

  var body: some View {
    if let thread = threads.first {
      ChatConversationView(thread: thread)
    } else {
      ContentUnavailableView(
        "Conversation unavailable",
        systemImage: "exclamationmark.bubble",
        description: Text("It may have been deleted.")
      )
    }
  }
}
