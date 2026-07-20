import SwiftUI

struct ProfilesLabView: View {
  @Environment(AppState.self) private var appState
  @State private var controller = ProfilesLabController()
  @State private var requestTask: Task<Void, Never>?
  @FocusState private var isInputFocused: Bool

  var body: some View {
    @Bindable var controller = controller

    Form {
      Section {
        Text(
          "Apple Dynamic Profiles keep one transcript while changing the "
            + "OpenAI model, instructions, reasoning, and tool policy."
        )
        .font(.callout)
      } footer: {
        Text(
          "This API is part of the OS 27 beta and may change with Xcode updates."
        )
      }

      Section("Models") {
        TextField("Fast model", text: $controller.fastModelID)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($isInputFocused)
        TextField("Deep model", text: $controller.deepModelID)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($isInputFocused)
        Button("Apply model changes", systemImage: "arrow.clockwise") {
          controller.reset()
        }
        .disabled(controller.hasSession == false)
      }

      Section("Active profile") {
        Picker("Mode", selection: $controller.mode) {
          ForEach(OpenAIProfileMode.allCases) {
            Text($0.label).tag($0)
          }
        }
        .pickerStyle(.segmented)

        if controller.hasSession {
          Label(
            "Shared transcript: \(controller.turnCount) turn"
              + (controller.turnCount == 1 ? "" : "s"),
            systemImage: "checkmark.circle.fill"
          )
          .foregroundStyle(.secondary)
        }
      }

      Section("Prompt") {
        TextField("Prompt", text: $controller.prompt, axis: .vertical)
          .lineLimit(2...6)
          .focused($isInputFocused)
        Button(
          controller.isRunning ? "Cancel response" : "Respond with profile",
          systemImage:
            controller.isRunning ? "stop.fill" : "arrow.up.circle.fill",
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

      if controller.isRunning {
        ProgressView("Using \(controller.mode.label.lowercased()) profile…")
      } else if !controller.output.isEmpty {
        Section("Response") {
          Text(controller.output)
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
    .navigationTitle("Dynamic Profiles")
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
      isInputFocused = false
      requestTask = Task {
        await controller.run(appState: appState)
      }
    }
  }
}
