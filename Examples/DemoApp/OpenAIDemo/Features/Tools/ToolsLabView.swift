import SwiftUI

struct ToolsLabView: View {
  @Environment(AppState.self) private var appState
  @State private var controller = ToolsLabController()
  @State private var requestTask: Task<Void, Never>?
  @FocusState private var isPromptFocused: Bool

  var body: some View {
    Form {
      Section("Prompt") {
        TextField("Ask for a calculation or time", text: $controller.prompt, axis: .vertical)
          .lineLimit(2...6)
          .focused($isPromptFocused)
        Button(
          controller.isRunning ? "Cancel tool test" : "Run tool test",
          systemImage: controller.isRunning ? "stop.fill" : "play.fill",
          action: toggleRequest
        )
        .disabled(
          !controller.isRunning
            && (controller.prompt.trimmingCharacters(
              in: .whitespacesAndNewlines
            ).isEmpty
              || !appState.settings.hasCredential)
        )
      }

      Section("Result") {
        if controller.isRunning {
          ProgressView("Calling model and tools…")
        } else if controller.result.isEmpty {
          Text("No result yet.")
            .foregroundStyle(.secondary)
        } else {
          Text(controller.result)
            .textSelection(.enabled)
        }
      }

      if let error = controller.errorMessage {
        Section {
          ErrorBanner(message: error) {
            controller.errorMessage = nil
          }
        }
      }
    }
    .navigationTitle("Function Tools")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .scrollDismissesKeyboard(.interactively)
    .onDisappear {
      requestTask?.cancel()
    }
  }

  private func toggleRequest() {
    if controller.isRunning {
      requestTask?.cancel()
    } else {
      isPromptFocused = false
      requestTask = Task {
        await controller.run(appState: appState)
      }
    }
  }
}
