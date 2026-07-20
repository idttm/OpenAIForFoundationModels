import Foundation

/// Discrete capabilities used by the bridge and demo UI.
public enum ModelFeature: String, Sendable, Hashable, CaseIterable, Codable {
  case toolCalling
  case guidedGeneration
  case vision
  case reasoning
  case sampling
  case webSearch

  public var shortLabel: String {
    switch self {
    case .toolCalling: "Tools"
    case .guidedGeneration: "JSON"
    case .vision: "Vision"
    case .reasoning: "Reasoning"
    case .sampling: "Sampling"
    case .webSearch: "Web"
    }
  }
}

/// Common catalog filters for product surfaces.
public enum ModelUseCase: Sendable, Hashable {
  case chat
  case agent
  case reasoning
  case multimodal
  case structured
  case custom(ModelFilter)

  public var filter: ModelFilter {
    switch self {
    case .chat:
      ModelFilter()
    case .agent:
      ModelFilter(requiresTools: true)
    case .reasoning:
      ModelFilter(requiresReasoning: true)
    case .multimodal:
      ModelFilter(requiresVision: true)
    case .structured:
      ModelFilter(requiresGuidedGeneration: true)
    case .custom(let filter):
      filter
    }
  }
}

/// Snapshot used to drive settings without hard-coding view behavior.
public struct ModelUIConfiguration: Sendable, Hashable {
  public var modelID: String
  public var displayName: String
  public var owner: String?
  public var available: Set<ModelFeature>
  public var unavailable: Set<ModelFeature>
  public var showReasoningControls: Bool
  public var effortOptions: [OpenAIReasoning.Effort]
  public var defaultEffort: OpenAIReasoning.Effort?
  public var supportsTools: Bool
  public var supportsVision: Bool
  public var supportsGuidedGeneration: Bool
  public var supportsWebSearch: Bool
  public var suggestedReasoning: OpenAIReasoning?

  public var featureLabels: [String] {
    ModelFeature.allCases.compactMap {
      available.contains($0) ? $0.shortLabel : nil
    }
  }

  public func supports(_ feature: ModelFeature) -> Bool {
    available.contains(feature)
  }
}

public enum ModelCatalogError: Error, Sendable, Equatable, LocalizedError {
  case unknownModel(id: String)
  case catalogEmpty

  public var errorDescription: String? {
    switch self {
    case .unknownModel(let id):
      "Unknown OpenAI model id '\(id)'. Refresh the catalog or check the spelling."
    case .catalogEmpty:
      "The OpenAI model catalog is empty. Call refresh() first."
    }
  }
}
