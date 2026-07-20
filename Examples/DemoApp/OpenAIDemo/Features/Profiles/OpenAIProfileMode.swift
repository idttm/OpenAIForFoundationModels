import Foundation
import FoundationModels

enum OpenAIProfileMode: String, Sendable, CaseIterable, Identifiable {
  case fast
  case deep

  var id: String { rawValue }

  var label: String {
    switch self {
    case .fast:
      "Fast"
    case .deep:
      "Deep reasoning"
    }
  }
}

private enum OpenAIProfileModeKey: SessionPropertyKey {
  static var defaultValue: OpenAIProfileMode { .fast }
}

extension SessionPropertyValues {
  var openAIProfileMode: OpenAIProfileMode {
    get { self[OpenAIProfileModeKey.self] }
    set { self[OpenAIProfileModeKey.self] = newValue }
  }
}
