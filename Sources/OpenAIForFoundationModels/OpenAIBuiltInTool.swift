import Foundation

/// OpenAI-hosted tools that can be enabled alongside Foundation Models'
/// client-side `Tool` values.
public enum OpenAIBuiltInTool: String, Sendable, Hashable, CaseIterable, Codable {
  case webSearch
}
