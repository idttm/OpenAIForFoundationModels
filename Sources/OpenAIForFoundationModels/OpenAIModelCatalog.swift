import Foundation
import OpenAIAPI

/// Actor-isolated cache around OpenAI's `/v1/models` endpoint.
public actor OpenAIModelCatalog {
  public static let defaultBaseURL = URL(string: "https://api.openai.com/v1")!
  public static let defaultCacheTTL: TimeInterval = 3600

  private let client: OpenAIClient
  private let requestHeaders: [String: String]
  private let cacheTTL: TimeInterval
  private var cached: [OpenAIModel] = []
  private var byID: [String: OpenAIModel] = [:]
  private var fetchedAt: Date?
  private var inFlightRefresh: Task<[OpenAIModel], Error>?

  public init(
    auth: AuthMode,
    baseURL: URL = OpenAIModelCatalog.defaultBaseURL,
    cacheTTL: TimeInterval = OpenAIModelCatalog.defaultCacheTTL,
    accountScope: OpenAIAccountScope? = nil
  ) throws {
    try EndpointPolicy.validateBaseURL(baseURL, for: auth)

    let apiAuth: Configuration.Auth
    let headers: [String: String]
    switch auth {
    case .apiKey(let key) where !key.isEmpty:
      apiAuth = .apiKey(key)
      headers = [:]
    case .apiKey:
      apiAuth = .none
      headers = [:]
    case .proxied(let proxyHeaders):
      apiAuth = .none
      headers = EndpointPolicy.sanitizeProxyHeaders(proxyHeaders)
    }

    let sessionConfiguration = URLSessionConfiguration.default
    sessionConfiguration.timeoutIntervalForRequest = 60
    self.client = OpenAIClient(
      configuration: .init(
        auth: apiAuth,
        baseURL: baseURL,
        organizationID: accountScope?.organizationID,
        projectID: accountScope?.projectID
      ),
      transport: URLSessionTransport(
        session: URLSession(configuration: sessionConfiguration)
      )
    )
    self.requestHeaders = headers
    self.cacheTTL = cacheTTL
  }

  init(
    client: OpenAIClient,
    requestHeaders: [String: String] = [:],
    cacheTTL: TimeInterval = OpenAIModelCatalog.defaultCacheTTL
  ) {
    self.client = client
    self.requestHeaders = requestHeaders
    self.cacheTTL = cacheTTL
  }

  package func seed(_ models: [OpenAIModel]) {
    cached = models
    byID = Self.index(models)
    fetchedAt = .now
  }

  @discardableResult
  public func refresh(force: Bool = false) async throws -> [OpenAIModel] {
    if !force,
      let fetchedAt,
      Date().timeIntervalSince(fetchedAt) < cacheTTL,
      !cached.isEmpty
    {
      return cached
    }
    if let inFlightRefresh {
      return try await inFlightRefresh.value
    }

    let client = self.client
    let headers = self.requestHeaders
    let task = Task<[OpenAIModel], Error> {
      try await client.listModels(headers: headers)
        .map(OpenAIModel.init(descriptor:))
        .filter(\.capabilities.isGenerative)
        .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
    }
    inFlightRefresh = task

    do {
      let models = try await task.value
      cached = models
      byID = Self.index(models)
      fetchedAt = .now
      inFlightRefresh = nil
      return models
    } catch {
      inFlightRefresh = nil
      throw error
    }
  }

  public func models() -> [OpenAIModel] {
    cached
  }

  public func models(for useCase: ModelUseCase) -> [OpenAIModel] {
    models(matching: useCase.filter)
  }

  public func models(matching filter: ModelFilter) -> [OpenAIModel] {
    cached.filter(filter.matches)
  }

  public func model(id: String) -> OpenAIModel? {
    byID[id]
  }

  public func resolve(
    id: String,
    refreshIfNeeded: Bool = true
  ) async throws -> OpenAIModel {
    if let model = byID[id] { return model }
    if refreshIfNeeded {
      _ = try await refresh(force: !cached.isEmpty)
      if let model = byID[id] { return model }
    }
    if cached.isEmpty { throw ModelCatalogError.catalogEmpty }
    throw ModelCatalogError.unknownModel(id: id)
  }

  public func resolveIfPresent(
    id: String,
    refreshIfNeeded: Bool = true
  ) async throws -> OpenAIModel {
    do {
      return try await resolve(id: id, refreshIfNeeded: refreshIfNeeded)
    } catch is ModelCatalogError {
      return OpenAIModel(id: id)
    }
  }

  private static func index(_ models: [OpenAIModel]) -> [String: OpenAIModel] {
    Dictionary(
      models.map { ($0.id, $0) },
      uniquingKeysWith: { _, last in last }
    )
  }
}

public struct ModelFilter: Sendable, Hashable {
  public var query: String?
  public var owner: String?
  public var requiresTools: Bool?
  public var requiresGuidedGeneration: Bool?
  public var requiresVision: Bool?
  public var requiresReasoning: Bool?
  public var requiresAllFeatures: Set<ModelFeature>?
  public var requiresAnyFeature: Set<ModelFeature>?

  public init(
    query: String? = nil,
    owner: String? = nil,
    requiresTools: Bool? = nil,
    requiresGuidedGeneration: Bool? = nil,
    requiresVision: Bool? = nil,
    requiresReasoning: Bool? = nil,
    requiresAllFeatures: Set<ModelFeature>? = nil,
    requiresAnyFeature: Set<ModelFeature>? = nil
  ) {
    self.query = query
    self.owner = owner
    self.requiresTools = requiresTools
    self.requiresGuidedGeneration = requiresGuidedGeneration
    self.requiresVision = requiresVision
    self.requiresReasoning = requiresReasoning
    self.requiresAllFeatures = requiresAllFeatures
    self.requiresAnyFeature = requiresAnyFeature
  }

  public static func `for`(_ useCase: ModelUseCase) -> ModelFilter {
    useCase.filter
  }

  public func matches(_ model: OpenAIModel) -> Bool {
    if let query, !query.isEmpty {
      let needle = query.lowercased()
      let haystack = [model.id, model.name, model.owner ?? ""]
        .joined(separator: " ")
        .lowercased()
      if !haystack.contains(needle) { return false }
    }
    if let owner, model.owner != owner { return false }
    if requiresTools == true, !model.capabilities.toolCalling { return false }
    if requiresGuidedGeneration == true, !model.capabilities.guidedGeneration {
      return false
    }
    if requiresVision == true, !model.capabilities.vision { return false }
    if requiresReasoning == true, !model.capabilities.reasoning { return false }
    if let all = requiresAllFeatures, !all.isSubset(of: model.features) {
      return false
    }
    if let any = requiresAnyFeaturesNormalized,
      !any.isEmpty,
      any.isDisjoint(with: model.features)
    {
      return false
    }
    return true
  }

  private var requiresAnyFeaturesNormalized: Set<ModelFeature>? {
    requiresAnyFeature
  }
}

extension OpenAIModel.Capabilities {
  fileprivate var isGenerative: Bool {
    toolCalling || guidedGeneration || vision || reasoning || sampling || webSearch
  }
}
