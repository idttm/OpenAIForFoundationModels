import Foundation
import FoundationModels
import Observation
import OpenAIForFoundationModels

@Observable
@MainActor
final class ProfilesLabController {
  var mode: OpenAIProfileMode = .fast
  var fastModelID = "gpt-5-mini"
  var deepModelID = OpenAIModel.default.id
  var prompt =
    "Explain why switching profiles inside one model session is useful."
  private(set) var output = ""
  private(set) var turnCount = 0
  private(set) var isRunning = false
  var errorMessage: String?

  @ObservationIgnored private var session: LanguageModelSession?

  var hasSession: Bool { session != nil }

  func run(appState: AppState) async {
    guard !isRunning else { return }
    isRunning = true
    defer { isRunning = false }
    errorMessage = nil

    do {
      let activeSession = try session ?? makeSession(appState: appState)
      session = activeSession
      activeSession.properties.openAIProfileMode = mode
      output = try await activeSession.respond(to: prompt).content
      turnCount += 1
    } catch is CancellationError {
      return
    } catch {
      errorMessage = ModelFactory.format(error)
    }
  }

  func reset() {
    session = nil
    output = ""
    turnCount = 0
    errorMessage = nil
  }

  private func makeSession(appState: AppState) throws -> LanguageModelSession {
    let settings = appState.settings
    let fastModel = appState.model(for: fastModelID)
    let deepModel = appState.model(for: deepModelID)
    let tools =
      settings.enableClientTools
        && fastModel.capabilities.toolCalling
        && deepModel.capabilities.toolCalling
      ? SampleTools.all()
      : []

    let fast = OpenAILanguageModel(
      catalogModel: fastModel,
      auth: try settings.authMode(),
      reasoning: nil,
      applySuggestedReasoning: false,
      builtInTools: settings.enableWebSearch ? [.webSearch] : [],
      accountScope: settings.accountScope,
      strictCapabilities: settings.strictCapabilities,
      storeResponses: settings.storeResponses,
      baseURL: try settings.baseURL()
    )
    let deep = OpenAILanguageModel(
      catalogModel: deepModel,
      auth: try settings.authMode(),
      reasoning: .effort(.high),
      applySuggestedReasoning: false,
      builtInTools: settings.enableWebSearch ? [.webSearch] : [],
      accountScope: settings.accountScope,
      strictCapabilities: settings.strictCapabilities,
      storeResponses: settings.storeResponses,
      baseURL: try settings.baseURL()
    )
    return LanguageModelSession(
      profile: OpenAIProfileSet(
        fast: fast,
        deep: deep,
        tools: tools
      )
    )
  }
}
