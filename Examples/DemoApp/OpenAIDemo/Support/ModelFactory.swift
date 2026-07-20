import Foundation
import FoundationModels
import OpenAIForFoundationModels

@MainActor
enum ModelFactory {
  static func makeLanguageModel(
    settings: DemoSettings,
    model: OpenAIModel
  ) throws -> OpenAILanguageModel {
    OpenAILanguageModel(
      catalogModel: model,
      auth: try settings.authMode(),
      reasoning: settings.reasoningChoice.reasoning,
      applySuggestedReasoning: settings.reasoningChoice == .automatic,
      builtInTools: settings.enableWebSearch ? [.webSearch] : [],
      accountScope: settings.accountScope,
      strictCapabilities: settings.strictCapabilities,
      storeResponses: settings.storeResponses,
      baseURL: try settings.baseURL()
    )
  }

  static func makeSession(
    settings: DemoSettings,
    model: OpenAIModel,
    tools: [any Tool] = [],
    transcript: Transcript? = nil
  ) throws -> LanguageModelSession {
    let languageModel = try makeLanguageModel(
      settings: settings,
      model: model
    )
    let enabledTools =
      settings.enableClientTools && model.capabilities.toolCalling
      ? tools
      : []

    if let transcript {
      return LanguageModelSession(
        model: languageModel,
        tools: enabledTools,
        transcript: transcript
      )
    }
    return LanguageModelSession(
      model: languageModel,
      tools: enabledTools,
      instructions:
        "You are a helpful assistant. Be accurate, clear, and concise."
    )
  }

  static func format(_ error: any Error) -> String {
    if error is CancellationError { return "Cancelled." }
    if let toolError = error as? LanguageModelSession.ToolCallError {
      let detail = OpenAIError.sanitize(
        toolError.underlyingError.localizedDescription
      )
      if detail.localizedStandardContains("parse generated content")
        || detail.localizedStandardContains("decode")
      {
        return
          "The model returned invalid arguments for the "
          + "\(toolError.tool.name) tool. Try the request again."
      }
      return
        "The \(toolError.tool.name) tool could not complete the request. "
        + detail
    }
    if let value = error as? LocalizedError,
      let message = value.errorDescription
    {
      return OpenAIError.sanitize(message)
    }
    return OpenAIError.sanitize(error.localizedDescription)
  }
}
