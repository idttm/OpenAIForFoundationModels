import Foundation

/// One item in the OpenAI Responses API `input` array.
package enum ResponseInputItem: Sendable, Hashable, Codable {
  case message(role: MessageRole, content: InputContent)
  case functionCall(id: String?, callID: String, name: String, arguments: String)
  case functionCallOutput(callID: String, output: String)

  package static func developer(_ text: String) -> Self {
    .message(role: .developer, content: .text(text))
  }

  package static func user(_ text: String) -> Self {
    .message(role: .user, content: .text(text))
  }

  package static func assistant(_ text: String) -> Self {
    .message(role: .assistant, content: .text(text))
  }

  package var messageRole: MessageRole? {
    guard case .message(let role, _) = self else { return nil }
    return role
  }

  package var messageContent: InputContent? {
    guard case .message(_, let content) = self else { return nil }
    return content
  }

  private enum CodingKeys: String, CodingKey {
    case type, role, content, id, name, arguments, output
    case callID = "call_id"
  }

  package init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let type = try c.decodeIfPresent(String.self, forKey: .type) ?? "message"
    switch type {
    case "message":
      self = .message(
        role: try c.decode(MessageRole.self, forKey: .role),
        content: try c.decode(InputContent.self, forKey: .content)
      )
    case "function_call":
      self = .functionCall(
        id: try c.decodeIfPresent(String.self, forKey: .id),
        callID: try c.decode(String.self, forKey: .callID),
        name: try c.decode(String.self, forKey: .name),
        arguments: try c.decode(String.self, forKey: .arguments)
      )
    case "function_call_output":
      self = .functionCallOutput(
        callID: try c.decode(String.self, forKey: .callID),
        output: try c.decode(String.self, forKey: .output)
      )
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .type,
        in: c,
        debugDescription: "Unsupported Responses input item '\(type)'"
      )
    }
  }

  package func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .message(let role, let content):
      try c.encode("message", forKey: .type)
      try c.encode(role, forKey: .role)
      try c.encode(content, forKey: .content)
    case .functionCall(let id, let callID, let name, let arguments):
      try c.encode("function_call", forKey: .type)
      try c.encodeIfPresent(id, forKey: .id)
      try c.encode(callID, forKey: .callID)
      try c.encode(name, forKey: .name)
      try c.encode(arguments, forKey: .arguments)
    case .functionCallOutput(let callID, let output):
      try c.encode("function_call_output", forKey: .type)
      try c.encode(callID, forKey: .callID)
      try c.encode(output, forKey: .output)
    }
  }
}

package enum MessageRole: String, Sendable, Hashable, Codable {
  case developer
  case user
  case assistant
}

package enum InputContent: Sendable, Hashable, Codable {
  case text(String)
  case parts([InputContentPart])

  package init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let text = try? c.decode(String.self) {
      self = .text(text)
    } else {
      self = .parts(try c.decode([InputContentPart].self))
    }
  }

  package func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .text(let text):
      try c.encode(text)
    case .parts(let parts):
      try c.encode(parts)
    }
  }

  package var textValue: String {
    switch self {
    case .text(let text):
      return text
    case .parts(let parts):
      return parts.compactMap(\.textValue).joined()
    }
  }
}

package enum InputContentPart: Sendable, Hashable, Codable {
  case text(String)
  case imageURL(String, detail: String?)

  package var textValue: String? {
    guard case .text(let text) = self else { return nil }
    return text
  }

  private enum CodingKeys: String, CodingKey {
    case type, text, detail
    case imageURL = "image_url"
  }

  package init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    switch try c.decode(String.self, forKey: .type) {
    case "input_text":
      self = .text(try c.decode(String.self, forKey: .text))
    case "input_image":
      self = .imageURL(
        try c.decode(String.self, forKey: .imageURL),
        detail: try c.decodeIfPresent(String.self, forKey: .detail)
      )
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .type,
        in: c,
        debugDescription: "Unsupported Responses content part"
      )
    }
  }

  package func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .text(let text):
      try c.encode("input_text", forKey: .type)
      try c.encode(text, forKey: .text)
    case .imageURL(let url, let detail):
      try c.encode("input_image", forKey: .type)
      try c.encode(url, forKey: .imageURL)
      try c.encodeIfPresent(detail, forKey: .detail)
    }
  }
}
