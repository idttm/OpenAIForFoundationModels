import Foundation
import FoundationModels
import Observation

@Observable
@MainActor
final class GuidedLabController {
  var prompt = "Plan a three-day food-focused trip to Chicago."
  private(set) var plan: TripPlan?
  private(set) var isRunning = false
  var errorMessage: String?

  func run(appState: AppState) async {
    guard !isRunning else { return }
    isRunning = true
    defer { isRunning = false }
    errorMessage = nil
    plan = nil

    do {
      let model = appState.model(for: appState.settings.selectedModelID)
      let session = try ModelFactory.makeSession(
        settings: appState.settings,
        model: model
      )
      plan = try await session.respond(
        to: prompt,
        generating: TripPlan.self
      ).content
    } catch is CancellationError {
      return
    } catch {
      errorMessage = ModelFactory.format(error)
    }
  }
}
