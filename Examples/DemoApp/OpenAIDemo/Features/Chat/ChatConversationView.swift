import SwiftData
import SwiftUI

struct ChatConversationView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(AppState.self) private var appState
  @Bindable var thread: ChatThread
  @State private var controller = ChatSessionController()
  @State private var draft = ""
  @State private var isModelPickerPresented = false
  @FocusState private var isComposerFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      if !appState.settings.hasCredential {
        CredentialBanner()
      }

      ChatTranscriptView(
        messages: thread.messages.sorted { $0.createdAt < $1.createdAt },
        streamingMessageID: controller.streamingMessageID
      )

      if let errorMessage = controller.errorMessage {
        ErrorBanner(message: errorMessage) {
          controller.errorMessage = nil
        }
      }

      ChatComposerView(
        text: $draft,
        isStreaming: controller.isStreaming,
        isEnabled: appState.settings.hasCredential,
        send: send,
        stop: controller.stop,
        focus: $isComposerFocused
      )
    }
    .navigationTitle(thread.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      Button("Choose model", systemImage: "cpu") {
        isComposerFocused = false
        isModelPickerPresented = true
      }
    }
    .sheet(isPresented: $isModelPickerPresented) {
      ModelSelectionView(
        title: "Conversation Model",
        selection: $thread.modelID
      )
    }
    .onChange(of: thread.modelID) {
      thread.updatedAt = .now
      try? modelContext.save()
    }
  }

  private func send() {
    let value = draft
    draft = ""
    Task {
      await controller.send(
        text: value,
        thread: thread,
        model: appState.model(for: thread.modelID),
        settings: appState.settings,
        modelContext: modelContext
      )
    }
  }
}
