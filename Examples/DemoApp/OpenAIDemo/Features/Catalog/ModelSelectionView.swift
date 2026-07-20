import OpenAIForFoundationModels
import SwiftUI

struct ModelSelectionView: View {
  let title: String
  @Binding var selection: String

  @Environment(AppState.self) private var appState
  @Environment(\.dismiss) private var dismiss
  @State private var searchText = ""
  @State private var customModelID = ""

  private var models: [OpenAIModel] {
    var byID = Dictionary(
      appState.catalogModels.map { ($0.id, $0) },
      uniquingKeysWith: { _, latest in latest }
    )
    byID[OpenAIModel.default.id] = byID[OpenAIModel.default.id] ?? .default
    byID[OpenAIModel.gpt5Mini.id] =
      byID[OpenAIModel.gpt5Mini.id] ?? .gpt5Mini
    byID[selection] = byID[selection] ?? appState.model(for: selection)

    let filter = ModelFilter(query: searchText)
    return byID.values
      .filter(filter.matches)
      .sorted {
        $0.name.localizedStandardCompare($1.name) == .orderedAscending
      }
  }

  private var trimmedCustomModelID: String {
    customModelID.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    NavigationStack {
      List {
        Section("Available models") {
          ForEach(models) { model in
            Button {
              choose(model.id)
            } label: {
              HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                  Text(model.name)
                    .foregroundStyle(.primary)
                  if model.name != model.id {
                    Text(model.id)
                      .font(.subheadline.monospaced())
                      .foregroundStyle(.secondary)
                  }
                }
                Spacer()
                if model.id == selection {
                  Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                }
              }
              .contentShape(Rectangle())
            }
            .accessibilityValue(model.id == selection ? "Selected" : "")
          }
        }

        if searchText.isEmpty {
          Section {
            TextField("Model ID", text: $customModelID)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .submitLabel(.done)
              .onSubmit(chooseCustomModel)

            Button(
              "Use custom model",
              systemImage: "checkmark.circle",
              action: chooseCustomModel
            )
            .disabled(trimmedCustomModelID.isEmpty)
          } header: {
            Text("Custom model")
          } footer: {
            Text(
              "Use this when a model is available to your account but is not "
                + "shown in the catalog yet."
            )
          }
        }
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, prompt: "Search models")
      .scrollDismissesKeyboard(.interactively)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .primaryAction) {
          Button("Refresh", systemImage: "arrow.clockwise") {
            Task { await appState.refreshCatalog(force: true) }
          }
          .disabled(
            appState.isRefreshingCatalog || !appState.settings.hasCredential
          )
        }
      }
      .overlay {
        if appState.isRefreshingCatalog && appState.catalogModels.isEmpty {
          ProgressView("Loading OpenAI models…")
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
      }
      .task {
        customModelID = selection
        if appState.catalogModels.isEmpty && appState.settings.hasCredential {
          await appState.refreshCatalog()
        }
      }
    }
  }

  private func chooseCustomModel() {
    guard !trimmedCustomModelID.isEmpty else { return }
    choose(trimmedCustomModelID)
  }

  private func choose(_ modelID: String) {
    selection = modelID
    dismiss()
  }
}
