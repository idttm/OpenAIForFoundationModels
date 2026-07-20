import Foundation
import FoundationModels
import OpenAIAPI

/// Makes an OpenAI model available through Foundation Models'
/// `LanguageModelSession`.
///
/// ```swift
/// let model = OpenAILanguageModel(
///   name: .default,
///   auth: .apiKey(apiKey),
///   reasoning: .effort(.medium)
/// )
/// let session = LanguageModelSession(model: model)
/// let response = try await session.respond(to: "Plan a weekend in Kyoto.")
/// ```
public struct OpenAILanguageModel: Sendable {
  public let model: OpenAIModel
  public let baseURL: URL
  public let timeout: TimeInterval
  public let fixedReasoning: OpenAIReasoning?
  public let builtInTools: Set<OpenAIBuiltInTool>
  public let accountScope: OpenAIAccountScope?
  public let strictCapabilities: Bool
  public let storeResponses: Bool
  public let safetyIdentifier: String?
  public let promptCacheKey: String?
  let authMode: AuthMode

  public static let defaultBaseURL = URL(string: "https://api.openai.com/v1")!

  public init(
    name: OpenAIModel,
    auth: AuthMode,
    reasoning: OpenAIReasoning? = nil,
    builtInTools: Set<OpenAIBuiltInTool> = [],
    accountScope: OpenAIAccountScope? = nil,
    strictCapabilities: Bool = true,
    storeResponses: Bool = false,
    safetyIdentifier: String? = nil,
    promptCacheKey: String? = nil,
    baseURL: URL = OpenAILanguageModel.defaultBaseURL,
    timeout: TimeInterval = 120
  ) {
    self.model = name
    self.authMode = auth
    self.fixedReasoning = reasoning
    self.builtInTools = builtInTools
    self.accountScope = accountScope
    self.strictCapabilities = strictCapabilities
    self.storeResponses = storeResponses
    self.safetyIdentifier = safetyIdentifier
    self.promptCacheKey = promptCacheKey
    self.baseURL = baseURL
    self.timeout = timeout
  }

  public init(
    name: String,
    auth: AuthMode,
    reasoning: OpenAIReasoning? = nil,
    builtInTools: Set<OpenAIBuiltInTool> = [],
    accountScope: OpenAIAccountScope? = nil,
    strictCapabilities: Bool = true,
    storeResponses: Bool = false,
    safetyIdentifier: String? = nil,
    promptCacheKey: String? = nil,
    baseURL: URL = OpenAILanguageModel.defaultBaseURL,
    timeout: TimeInterval = 120
  ) {
    self.init(
      name: OpenAIModel(id: name),
      auth: auth,
      reasoning: reasoning,
      builtInTools: builtInTools,
      accountScope: accountScope,
      strictCapabilities: strictCapabilities,
      storeResponses: storeResponses,
      safetyIdentifier: safetyIdentifier,
      promptCacheKey: promptCacheKey,
      baseURL: baseURL,
      timeout: timeout
    )
  }

  public init(
    catalogModel: OpenAIModel,
    auth: AuthMode,
    reasoning: OpenAIReasoning? = nil,
    applySuggestedReasoning: Bool = true,
    builtInTools: Set<OpenAIBuiltInTool> = [],
    accountScope: OpenAIAccountScope? = nil,
    strictCapabilities: Bool = true,
    storeResponses: Bool = false,
    safetyIdentifier: String? = nil,
    promptCacheKey: String? = nil,
    baseURL: URL = OpenAILanguageModel.defaultBaseURL,
    timeout: TimeInterval = 120
  ) {
    self.init(
      name: catalogModel,
      auth: auth,
      reasoning:
        reasoning
        ?? (applySuggestedReasoning
          ? catalogModel.suggestedReasoning
          : nil),
      builtInTools: builtInTools,
      accountScope: accountScope,
      strictCapabilities: strictCapabilities,
      storeResponses: storeResponses,
      safetyIdentifier: safetyIdentifier,
      promptCacheKey: promptCacheKey,
      baseURL: baseURL,
      timeout: timeout
    )
  }

  public func authenticateIfNeeded() async throws {}

  public var uiConfiguration: ModelUIConfiguration {
    model.uiConfiguration
  }
}

extension OpenAILanguageModel: LanguageModel {
  public typealias Executor = OpenAIExecutor

  public var capabilities: LanguageModelCapabilities {
    var result: [LanguageModelCapabilities.Capability] = []
    if model.capabilities.toolCalling { result.append(.toolCalling) }
    if model.capabilities.vision { result.append(.vision) }
    if model.capabilities.reasoning { result.append(.reasoning) }
    if model.capabilities.guidedGeneration { result.append(.guidedGeneration) }
    return LanguageModelCapabilities(result)
  }

  public var executorConfiguration: OpenAIExecutor.Configuration {
    .init(
      model: model,
      baseURL: baseURL,
      authMode: authMode,
      fixedReasoning: fixedReasoning,
      builtInTools: builtInTools,
      accountScope: accountScope,
      strictCapabilities: strictCapabilities,
      storeResponses: storeResponses,
      safetyIdentifier: safetyIdentifier,
      promptCacheKey: promptCacheKey,
      timeout: timeout
    )
  }
}
