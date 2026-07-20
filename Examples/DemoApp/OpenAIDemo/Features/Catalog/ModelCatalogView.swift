import OpenAIForFoundationModels
import SwiftUI

struct ModelCatalogView: View {
  @Environment(AppState.self) private var appState
  @State private var searchText = ""

  private var filteredModels: [OpenAIModel] {
    let filter = ModelFilter(query: searchText)
    return appState.catalogModels.filter(filter.matches)
  }

  var body: some View {
    NavigationStack {
      Group {
        if !appState.settings.hasCredential {
          ContentUnavailableView(
            "Credentials required",
            systemImage: "key",
            description: Text(
              "Open Settings to add an API key or configure a relay."
            )
          )
        } else if appState.isRefreshingCatalog && appState.catalogModels.isEmpty {
          ProgressView("Loading OpenAI models…")
        } else if filteredModels.isEmpty {
          ContentUnavailableView.search
        } else {
          List(filteredModels) { model in
            NavigationLink(value: model.id) {
              ModelRow(model: model)
            }
          }
        }
      }
      .navigationTitle("OpenAI Models")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, prompt: "Search models")
      .scrollDismissesKeyboard(.interactively)
      .navigationDestination(for: String.self) {
        ModelDetailView(model: appState.model(for: $0))
      }
      .toolbar {
        Button("Refresh models", systemImage: "arrow.clockwise") {
          Task { await appState.refreshCatalog(force: true) }
        }
        .disabled(appState.isRefreshingCatalog || !appState.settings.hasCredential)
      }
      .task {
        if appState.catalogModels.isEmpty && appState.settings.hasCredential {
          await appState.refreshCatalog()
        }
      }
      .overlay(alignment: .bottom) {
        if let error = appState.catalogError {
          ErrorBanner(message: error) {
            appState.catalogError = nil
          }
        }
      }
    }
  }
}
