import SwiftUI

struct GuidedLabView: View {
  @Environment(AppState.self) private var appState
  @State private var controller = GuidedLabController()
  @State private var requestTask: Task<Void, Never>?
  @FocusState private var isPromptFocused: Bool

  var body: some View {
    Form {
      Section("Prompt") {
        TextField("Describe a trip", text: $controller.prompt, axis: .vertical)
          .lineLimit(2...6)
          .focused($isPromptFocused)
        Button(
          controller.isRunning ? "Cancel generation" : "Generate typed plan",
          systemImage: controller.isRunning ? "stop.fill" : "curlybraces",
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
        ProgressView("Generating structured output…")
      } else if let plan = controller.plan {
        Section("Typed result") {
          LabeledContent("Destination", value: plan.destination)
          LabeledContent("Days", value: plan.days.formatted())
          LabeledContent(
            "Daily budget",
            value: plan.dailyBudgetUSD.formatted(
              .currency(code: "USD").precision(.fractionLength(0))
            )
          )
          ForEach(Array(plan.highlights.enumerated()), id: \.offset) {
            Label($0.element, systemImage: "\($0.offset + 1).circle")
          }
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
    .navigationTitle("Guided Generation")
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
