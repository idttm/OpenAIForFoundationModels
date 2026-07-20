import Foundation
import OpenAIForFoundationModels

enum ReasoningChoice: String, CaseIterable, Identifiable {
  case automatic
  case max
  case xhigh
  case high
  case medium
  case low
  case minimal
  case off

  var id: Self { self }

  var label: String {
    switch self {
    case .automatic: "Automatic"
    case .max: "Max"
    case .xhigh: "Extra high"
    case .high: "High"
    case .medium: "Medium"
    case .low: "Low"
    case .minimal: "Minimal"
    case .off: "Off"
    }
  }

  var reasoning: OpenAIReasoning? {
    switch self {
    case .automatic: nil
    case .max: .effort(.max)
    case .xhigh: .effort(.xhigh)
    case .high: .effort(.high)
    case .medium: .effort(.medium)
    case .low: .effort(.low)
    case .minimal: .effort(.minimal)
    case .off: .disabled
    }
  }
}
