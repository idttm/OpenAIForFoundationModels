import SwiftUI

struct SettingsView: View {
  @Environment(AppState.self) private var appState
  @State private var statusMessage: String?
  @State private var isModelPickerPresented = false
  @FocusState private var isInputFocused: Bool

  var body: some View {
    @Bindable var settings = appState.settings

    NavigationStack {
      Form {
        Section {
          Picker("Mode", selection: $settings.authKind) {
            ForEach(AuthKind.allCases) { kind in
              Text(kind.rawValue).tag(kind)
            }
          }

          if settings.authKind == .apiKey {
            SecureField("sk-proj-…", text: $settings.apiKey)
              .textContentType(.password)
              .privacySensitive()
              .focused($isInputFocused)
              .submitLabel(.done)
              .onSubmit(dismissKeyboard)
            Button("Save API key", systemImage: "key.fill", action: saveAPIKey)
            Button(
              "Remove API key",
              systemImage: "trash",
              role: .destructive,
              action: clearAPIKey
            )
            Link(
              "Open OpenAI API keys",
              destination: URL(string: "https://platform.openai.com/api-keys")!
            )
          } else {
            TextField("Relay base URL", text: $settings.relayURL)
              .textContentType(.URL)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .focused($isInputFocused)
            SecureField("Optional app token", text: $settings.relayToken)
              .textContentType(.password)
              .privacySensitive()
              .focused($isInputFocused)
              .submitLabel(.done)
              .onSubmit(dismissKeyboard)
            Button(
              "Save relay token",
              systemImage: "lock.fill",
              action: saveRelayToken
            )
            Button(
              "Remove relay token",
              systemImage: "trash",
              role: .destructive,
              action: clearRelayToken
            )
          }
        } header: {
          Text("Authentication")
        } footer: {
          Text(
            "Client-held API keys are suitable for development only. "
              + "Use a relay that adds the OpenAI key server-side in production."
          )
        }

        Section("Model") {
          Button {
            dismissKeyboard()
            isModelPickerPresented = true
          } label: {
            LabeledContent("Selected model") {
              Text(settings.selectedModelID)
                .font(.body.monospaced())
                .foregroundStyle(.secondary)
            }
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Choose model")
          Picker("Reasoning", selection: $settings.reasoningChoice) {
            ForEach(ReasoningChoice.allCases) {
              Text($0.label).tag($0)
            }
          }
          Toggle("OpenAI web search", isOn: $settings.enableWebSearch)
          Toggle("Client tools", isOn: $settings.enableClientTools)
          Toggle(
            "Strict capability checks",
            isOn: $settings.strictCapabilities
          )
        }

        Section {
          Toggle("Store responses at OpenAI", isOn: $settings.storeResponses)
        } header: {
          Text("Privacy")
        } footer: {
          Text(
            "Off by default. Conversation history in this demo is stored "
              + "locally with SwiftData."
          )
        }

        Section("Optional account scope") {
          TextField("Organization ID", text: $settings.organizationID)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isInputFocused)
          TextField("Project ID", text: $settings.projectID)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isInputFocused)
            .submitLabel(.done)
            .onSubmit(dismissKeyboard)
        }

        if let statusMessage {
          Section {
            Label(statusMessage, systemImage: "checkmark.circle")
              .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .scrollDismissesKeyboard(.interactively)
      .toolbar(isInputFocused ? .hidden : .visible, for: .tabBar)
      .sheet(isPresented: $isModelPickerPresented) {
        ModelSelectionView(
          title: "Default Model",
          selection: $settings.selectedModelID
        )
      }
      .onChange(of: settings.selectedModelID) {
        settings.persist()
      }
      .onDisappear {
        dismissKeyboard()
        settings.persist()
      }
    }
  }

  private func saveAPIKey() {
    dismissKeyboard()
    perform {
      try appState.settings.saveAPIKey()
      return "API key saved in Keychain."
    }
  }

  private func clearAPIKey() {
    dismissKeyboard()
    perform {
      try appState.settings.clearAPIKey()
      return "API key removed."
    }
  }

  private func saveRelayToken() {
    dismissKeyboard()
    perform {
      try appState.settings.saveRelayToken()
      appState.settings.persist()
      return "Relay settings saved."
    }
  }

  private func clearRelayToken() {
    dismissKeyboard()
    perform {
      try appState.settings.clearRelayToken()
      return "Relay token removed."
    }
  }

  private func perform(_ operation: () throws -> String) {
    do {
      statusMessage = try operation()
    } catch {
      statusMessage = ModelFactory.format(error)
    }
  }

  private func dismissKeyboard() {
    isInputFocused = false
  }
}
