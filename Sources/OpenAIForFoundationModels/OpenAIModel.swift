import Foundation
import OpenAIAPI

/// OpenAI model identity plus a conservative bridge capability profile.
///
/// OpenAI's `/v1/models` endpoint does not publish a complete feature matrix.
/// Catalog values therefore use documented family-level inference. Callers can
/// supply an explicit ``Capabilities`` value when they know a model deployment
/// has a different surface.
public struct OpenAIModel: Sendable, Hashable, Identifiable {
  public let id: String
  public let name: String
  public let owner: String?
  public let createdAt: Date?
  public let capabilities: Capabilities
  public let reasoning: ReasoningSupport?
  public let isCatalogBacked: Bool

  public init(
    id: String,
    name: String? = nil,
    owner: String? = nil,
    createdAt: Date? = nil,
    capabilities: Capabilities? = nil,
    reasoning: ReasoningSupport? = nil,
    isCatalogBacked: Bool = false
  ) {
    let inferred = capabilities ?? Capabilities.inferred(for: id)
    self.id = id
    self.name = name ?? id
    self.owner = owner
    self.createdAt = createdAt
    self.capabilities = inferred
    self.reasoning =
      reasoning
      ?? (inferred.reasoning ? ReasoningSupport.defaultForOpenAI : nil)
    self.isCatalogBacked = isCatalogBacked
  }

  package init(descriptor: ModelDescriptor) {
    self.init(
      id: descriptor.id,
      owner: descriptor.ownedBy,
      createdAt: descriptor.created.map {
        Date(timeIntervalSince1970: TimeInterval($0))
      },
      isCatalogBacked: true
    )
  }

  public var features: Set<ModelFeature> {
    var result: Set<ModelFeature> = []
    if capabilities.toolCalling { result.insert(.toolCalling) }
    if capabilities.guidedGeneration { result.insert(.guidedGeneration) }
    if capabilities.vision { result.insert(.vision) }
    if capabilities.reasoning { result.insert(.reasoning) }
    if capabilities.sampling { result.insert(.sampling) }
    if capabilities.webSearch { result.insert(.webSearch) }
    return result
  }

  public func supports(_ feature: ModelFeature) -> Bool {
    features.contains(feature)
  }

  public var suggestedReasoning: OpenAIReasoning? {
    guard capabilities.reasoning else { return nil }
    return .effort(reasoning?.defaultEffort ?? .medium)
  }

  public var uiConfiguration: ModelUIConfiguration {
    let available = features
    return ModelUIConfiguration(
      modelID: id,
      displayName: name,
      owner: owner,
      available: available,
      unavailable: Set(ModelFeature.allCases).subtracting(available),
      showReasoningControls: capabilities.reasoning,
      effortOptions: reasoning?.supportedEfforts ?? [],
      defaultEffort: reasoning?.defaultEffort,
      supportsTools: capabilities.toolCalling,
      supportsVision: capabilities.vision,
      supportsGuidedGeneration: capabilities.guidedGeneration,
      supportsWebSearch: capabilities.webSearch,
      suggestedReasoning: suggestedReasoning
    )
  }

  /// Current documented default used by the sample. Apps should make model
  /// selection configurable because model availability is account-dependent.
  public static let `default` = OpenAIModel(
    id: "gpt-5.6",
    name: "GPT-5.6"
  )

  public static let gpt5Mini = OpenAIModel(
    id: "gpt-5-mini",
    name: "GPT-5 mini"
  )

  public struct Capabilities: Sendable, Hashable {
    public var toolCalling: Bool
    public var guidedGeneration: Bool
    public var vision: Bool
    public var reasoning: Bool
    public var sampling: Bool
    public var webSearch: Bool

    public init(
      toolCalling: Bool = false,
      guidedGeneration: Bool = false,
      vision: Bool = false,
      reasoning: Bool = false,
      sampling: Bool = false,
      webSearch: Bool = false
    ) {
      self.toolCalling = toolCalling
      self.guidedGeneration = guidedGeneration
      self.vision = vision
      self.reasoning = reasoning
      self.sampling = sampling
      self.webSearch = webSearch
    }

    public static let unknown = Capabilities()

    public static func inferred(for id: String) -> Capabilities {
      let value = id.lowercased()
      let unsupportedSurfaceMarkers = [
        "audio", "embedding", "image", "moderation", "realtime",
        "search-preview", "sora", "speech", "transcribe", "transcription",
        "tts", "whisper",
      ]
      guard !unsupportedSurfaceMarkers.contains(where: value.contains) else {
        return .unknown
      }

      let isGPT5 = value.hasPrefix("gpt-5")
      let isGPT41 = value.hasPrefix("gpt-4.1")
      let isGPT4o = value.hasPrefix("gpt-4o")
      let isGPT4 = value == "gpt-4" || value.hasPrefix("gpt-4-")
      let isOFamily =
        value.hasPrefix("o1")
        || value.hasPrefix("o3")
        || value.hasPrefix("o4")
      guard isGPT5 || isGPT41 || isGPT4o || isGPT4 || isOFamily else {
        return .unknown
      }

      let isReasoning =
        isOFamily
        || isGPT5
      let hasVision =
        isGPT4o
        || isGPT41
        || isGPT5
        || value.hasPrefix("o3")
        || value.hasPrefix("o4")

      return Capabilities(
        toolCalling: true,
        guidedGeneration: true,
        vision: hasVision,
        reasoning: isReasoning,
        sampling: !isReasoning,
        webSearch: true
      )
    }
  }

  public struct ReasoningSupport: Sendable, Hashable {
    public var supportedEfforts: [OpenAIReasoning.Effort]
    public var defaultEffort: OpenAIReasoning.Effort

    public init(
      supportedEfforts: [OpenAIReasoning.Effort],
      defaultEffort: OpenAIReasoning.Effort = .medium
    ) {
      self.supportedEfforts = supportedEfforts
      self.defaultEffort = defaultEffort
    }

    public static let defaultForOpenAI = ReasoningSupport(
      supportedEfforts: [.max, .xhigh, .high, .medium, .low, .minimal, .none],
      defaultEffort: .medium
    )
  }
}

extension OpenAIModel: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(id: value)
  }
}
