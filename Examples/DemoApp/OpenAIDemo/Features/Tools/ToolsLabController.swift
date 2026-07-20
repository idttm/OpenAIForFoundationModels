import Foundation
import FoundationModels
import Observation

@Observable
@MainActor
final class ToolsLabController {
  var prompt = "What time is it, and what is 17 × 23?"
  private(set) var result = ""
  private(set) var isRunning = false
  var errorMessage: String?

  func run(appState: AppState) async {
    guard !isRunning else { return }
    isRunning = true
    defer { isRunning = false }
    errorMessage = nil
    result = ""

    do {
      let model = appState.model(for: appState.settings.selectedModelID)
      let session = try ModelFactory.makeSession(
        settings: appState.settings,
        model: model,
        tools: SampleTools.all()
      )
      result = try await session.respond(to: prompt).content
    } catch is CancellationError {
      return
    } catch {
      errorMessage = ModelFactory.format(error)
    }
  }
}
