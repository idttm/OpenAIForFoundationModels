import SwiftUI

struct ChatComposerView: View {
  @Binding var text: String
  let isStreaming: Bool
  let isEnabled: Bool
  let send: () -> Void
  let stop: () -> Void
  let focus: FocusState<Bool>.Binding

  var body: some View {
    HStack(alignment: .bottom) {
      TextField("Message OpenAI", text: $text, axis: .vertical)
        .lineLimit(1...6)
        .focused(focus)
        .textFieldStyle(.roundedBorder)
        .disabled(!isEnabled || isStreaming)
        .submitLabel(.send)
        .onSubmit(sendIfPossible)

      if isStreaming {
        Button("Stop generating", systemImage: "stop.fill", action: stop)
          .buttonStyle(.borderedProminent)
          .labelStyle(.iconOnly)
          .accessibilityLabel("Stop generating")
      } else {
        Button("Send message", systemImage: "arrow.up", action: send)
          .buttonStyle(.borderedProminent)
          .labelStyle(.iconOnly)
          .accessibilityLabel("Send message")
          .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isEnabled)
      }
    }
    .padding()
    .background(.bar)
  }

  private func sendIfPossible() {
    guard isEnabled, !isStreaming else { return }
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }
    send()
  }
}
