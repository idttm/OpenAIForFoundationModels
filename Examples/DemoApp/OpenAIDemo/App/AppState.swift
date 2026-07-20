import Foundation
import OpenAIForFoundationModels

@Observable
@MainActor
final class AppState {
  var selectedTab: AppTab = .chat
  var settings: DemoSettings
  var catalogModels: [OpenAIModel] = []
  var catalogError: String?
  var isRefreshingCatalog = false

  init(settings: DemoSettings = DemoSettings()) {
    self.settings = settings
    settings.load()
  }

  func refreshCatalog(force: Bool = false) async {
    guard settings.hasCredential else {
      catalogError = "Add an API key or configure a relay first."
      return
    }
    isRefreshingCatalog = true
    defer { isRefreshingCatalog = false }

    do {
      let catalog = try OpenAIModelCatalog(
        auth: settings.authMode(),
        baseURL: settings.baseURL(),
        accountScope: settings.accountScope
      )
      catalogModels = try await catalog.refresh(force: force)
      catalogError = nil
    } catch {
      catalogError = ModelFactory.format(error)
    }
  }

  func model(for id: String) -> OpenAIModel {
    catalogModels.first(where: { $0.id == id }) ?? OpenAIModel(id: id)
  }
}
