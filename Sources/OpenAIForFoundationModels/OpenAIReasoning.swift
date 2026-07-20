import Foundation
import OpenAIAPI

/// Reasoning configuration exposed by ``OpenAILanguageModel``.
public enum OpenAIReasoning: Sendable, Hashable {
  case automatic
  case effort(Effort)
  case disabled

  public enum Effort: String, Sendable, Hashable, CaseIterable, Codable {
    case max
    case xhigh
    case high
    case medium
    case low
    case minimal
    case none
  }
}

enum ReasoningPolicy {
  enum FrameworkReasoningLevel: Sendable, Equatable {
    case none
    case light
    case moderate
    case deep
    case custom(String)
  }

  static func resolve(
    fixed: OpenAIReasoning?,
    frameworkLevel: FrameworkReasoningLevel?,
    model: OpenAIModel,
    strict: Bool
  ) throws -> ReasoningConfig? {
    let requested =
      fixed.flatMap(requestedEffort)
      ?? frameworkLevel.flatMap(frameworkEffort)

    guard let requested else { return nil }
    guard model.capabilities.reasoning else {
      if strict {
        throw OpenAIError.unsupportedCapability(
          "\(model.id) does not advertise reasoning support."
        )
      }
      return nil
    }

    let effort = clamp(requested, supported: model.reasoning?.supportedEfforts)
    return ReasoningConfig(effort: wire(effort), summary: .auto)
  }

  static func clamp(
    _ effort: OpenAIReasoning.Effort,
    supported: [OpenAIReasoning.Effort]?
  ) -> OpenAIReasoning.Effort {
    guard let supported, !supported.isEmpty else { return effort }
    if supported.contains(effort) { return effort }

    let order = OpenAIReasoning.Effort.allCases
    guard let index = order.firstIndex(of: effort) else {
      return supported.first ?? .medium
    }
    for candidate in order[index...] where supported.contains(candidate) {
      return candidate
    }
    for candidate in order[..<index].reversed() where supported.contains(candidate) {
      return candidate
    }
    return supported.first ?? .medium
  }

  private static func requestedEffort(
    _ value: OpenAIReasoning
  ) -> OpenAIReasoning.Effort? {
    switch value {
    case .automatic:
      .medium
    case .effort(let effort):
      effort
    case .disabled:
      OpenAIReasoning.Effort.none
    }
  }

  private static func frameworkEffort(
    _ value: FrameworkReasoningLevel
  ) -> OpenAIReasoning.Effort? {
    switch value {
    case .none:
      nil
    case .light:
      .low
    case .moderate:
      .medium
    case .deep:
      .high
    case .custom(let value):
      OpenAIReasoning.Effort(rawValue: value)
    }
  }

  private static func wire(
    _ effort: OpenAIReasoning.Effort
  ) -> ReasoningConfig.Effort {
    ReasoningConfig.Effort(rawValue: effort.rawValue) ?? .medium
  }
}
