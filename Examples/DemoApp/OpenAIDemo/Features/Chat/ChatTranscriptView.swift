import SwiftUI

struct ChatTranscriptView: View {
  let messages: [ChatMessage]
  let streamingMessageID: UUID?

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 12) {
          if messages.isEmpty {
            ContentUnavailableView(
              "Start a conversation",
              systemImage: "sparkles",
              description: Text(
                "Messages are stored locally with SwiftData."
              )
            )
            .padding(.top)
          } else {
            ForEach(messages) { message in
              ChatMessageBubble(
                message: message,
                isStreaming: message.id == streamingMessageID
              )
              .id(message.id)
            }
          }
          Color.clear.frame(height: 1).id("chat-bottom")
        }
        .padding()
      }
      .scrollDismissesKeyboard(.interactively)
      .onChange(of: messages.map(\.text)) {
        proxy.scrollTo("chat-bottom", anchor: .bottom)
      }
    }
  }
}
