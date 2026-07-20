import Foundation

/// A strict function tool for the OpenAI Responses API.
package struct ToolDefinition: Sendable, Hashable, Codable {
  package var type: String
  package var name: String
  package var description: String?
  package var parameters: JSONValue
  package var strict: Bool

  package init(
    name: String,
    description: String?,
    parameters: JSONValue,
    strict: Bool = true
  ) {
    self.type = "function"
    self.name = name
    self.description = description
    self.parameters = parameters
    self.strict = strict
  }
}

package enum ToolChoice: Sendable, Hashable, Codable {
  case none
  case auto
  case required
  case function(name: String)

  package init(from decoder: Decoder) throws {
    if let s = try? decoder.singleValueContainer().decode(String.self) {
      switch s {
      case "none": self = .none
      case "auto": self = .auto
      case "required": self = .required
      default:
        throw DecodingError.dataCorrupted(
          .init(codingPath: decoder.codingPath, debugDescription: "Unknown tool_choice '\(s)'")
        )
      }
      return
    }
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let type = try c.decode(String.self, forKey: .type)
    guard type == "function" else {
      throw DecodingError.dataCorruptedError(
        forKey: .type, in: c, debugDescription: "Expected function tool_choice"
      )
    }
    self = .function(name: try c.decode(String.self, forKey: .name))
  }

  package func encode(to encoder: Encoder) throws {
    switch self {
    case .none:
      var c = encoder.singleValueContainer()
      try c.encode("none")
    case .auto:
      var c = encoder.singleValueContainer()
      try c.encode("auto")
    case .required:
      var c = encoder.singleValueContainer()
      try c.encode("required")
    case .function(let name):
      var c = encoder.container(keyedBy: CodingKeys.self)
      try c.encode("function", forKey: .type)
      try c.encode(name, forKey: .name)
    }
  }

  private enum CodingKeys: String, CodingKey { case type, name }
}
