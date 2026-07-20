import SwiftUI

struct ChatMessageBubble: View {
  let message: ChatMessage
  let isStreaming: Bool

  var body: some View {
    HStack {
      if message.role == .user { Spacer(minLength: 44) }

      VStack(alignment: message.role == .user ? .trailing : .leading) {
        Text(message.role == .user ? "You" : "OpenAI")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Group {
          if message.text.isEmpty && isStreaming {
            Label("Thinking", systemImage: "ellipsis")
              .foregroundStyle(.secondary)
          } else {
            Text(message.text)
              .textSelection(.enabled)
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
          message.role == .user
            ? Color.accentColor.opacity(0.16)
            : Color.secondary.opacity(0.1),
          in: RoundedRectangle(cornerRadius: 18)
        )
      }

      if message.role == .assistant { Spacer(minLength: 44) }
    }
    .accessibilityElement(children: .combine)
  }
}
