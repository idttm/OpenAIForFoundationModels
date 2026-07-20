import Foundation
import FoundationModels
import OpenAIAPI

/// Executes Foundation Models generation requests against OpenAI Responses.
public struct OpenAIExecutor: LanguageModelExecutor {
  public typealias Model = OpenAILanguageModel

  public struct Configuration: Hashable, Sendable {
    public let model: OpenAIModel
    public let baseURL: URL
    public let authMode: AuthMode
    public let fixedReasoning: OpenAIReasoning?
    public let builtInTools: Set<OpenAIBuiltInTool>
    public let accountScope: OpenAIAccountScope?
    public let strictCapabilities: Bool
    public let storeResponses: Bool
    public let safetyIdentifier: String?
    public let promptCacheKey: String?
    public let timeout: TimeInterval

    public init(
      model: OpenAIModel,
      baseURL: URL,
      authMode: AuthMode,
      fixedReasoning: OpenAIReasoning? = nil,
      builtInTools: Set<OpenAIBuiltInTool> = [],
      accountScope: OpenAIAccountScope? = nil,
      strictCapabilities: Bool = true,
      storeResponses: Bool = false,
      safetyIdentifier: String? = nil,
      promptCacheKey: String? = nil,
      timeout: TimeInterval
    ) {
      self.model = model
      self.baseURL = baseURL
      self.authMode = authMode
      self.fixedReasoning = fixedReasoning
      self.builtInTools = builtInTools
      self.accountScope = accountScope
      self.strictCapabilities = strictCapabilities
      self.storeResponses = storeResponses
      self.safetyIdentifier = safetyIdentifier
      self.promptCacheKey = promptCacheKey
      self.timeout = timeout
    }
  }

  private let configuration: Configuration
  private let client: OpenAIClient

  public init(configuration: Configuration) throws {
    try EndpointPolicy.validateBaseURL(
      configuration.baseURL,
      for: configuration.authMode
    )
    let sessionConfiguration = URLSessionConfiguration.default
    sessionConfiguration.timeoutIntervalForRequest = configuration.timeout
    self.init(
      configuration: configuration,
      transport: URLSessionTransport(
        session: URLSession(configuration: sessionConfiguration)
      )
    )
  }

  init(configuration: Configuration, transport: any HTTPTransport) {
    self.configuration = configuration

    let auth: OpenAIAPI.Configuration.Auth
    switch configuration.authMode {
    case .apiKey(let key) where !key.isEmpty:
      auth = .apiKey(key)
    case .apiKey, .proxied:
      auth = .none
    }

    self.client = OpenAIClient(
      configuration: .init(
        auth: auth,
        baseURL: configuration.baseURL,
        organizationID: configuration.accountScope?.organizationID,
        projectID: configuration.accountScope?.projectID
      ),
      transport: transport
    )
  }

  public func prewarm(
    model: OpenAILanguageModel,
    transcript: Transcript
  ) {}

  public func respond(
    to request: LanguageModelExecutorGenerationRequest,
    model: OpenAILanguageModel,
    streamingInto channel: LanguageModelExecutorGenerationChannel
  ) async throws {
    do {
      try EndpointPolicy.validateBaseURL(
        configuration.baseURL,
        for: configuration.authMode
      )

      let built = try RequestBuilder.build(
        from: request,
        model: configuration.model,
        fixedReasoning: configuration.fixedReasoning,
        builtInTools: configuration.builtInTools,
        storeResponses: configuration.storeResponses,
        safetyIdentifier: configuration.safetyIdentifier,
        promptCacheKey: configuration.promptCacheKey,
        strictCapabilities: configuration.strictCapabilities
      )

      let headers = try authHeaders()
      try await EventTranslator().translate(
        client.stream(built.request, headers: headers),
        into: channel
      )
    } catch {
      throw ErrorMapper.map(error)
    }
  }

  private func authHeaders() throws -> [String: String] {
    switch configuration.authMode {
    case .apiKey(let key):
      guard !key.isEmpty else {
        throw OpenAIError.missingOrInvalidCredential
      }
      return [:]
    case .proxied:
      return configuration.authMode.sanitizedProxyHeaders
    }
  }
}
