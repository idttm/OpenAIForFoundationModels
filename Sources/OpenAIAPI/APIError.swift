import Foundation

/// Error envelope returned by OpenAI (HTTP body or stream error).
package struct APIError: Error, Sendable, Hashable, Codable {
  package enum Kind: String, Sendable, Hashable, Codable {
    case invalidRequest = "invalid_request_error"
    case authentication = "authentication_error"
    case permission = "permission_error"
    case notFound = "not_found_error"
    case rateLimit = "rate_limit_error"
    case insufficientCredits = "insufficient_quota"
    case paymentRequired = "payment_required"
    case contextLength = "context_length_exceeded"
    case api = "api_error"
    case server = "server_error"
    case other
  }

  package var kind: Kind
  package var message: String
  package var statusCode: Int?
  package var metadata: [String: String]?

  package init(
    kind: Kind,
    message: String,
    statusCode: Int? = nil,
    metadata: [String: String]? = nil
  ) {
    self.kind = kind
    self.message = message
    self.statusCode = statusCode
    self.metadata = metadata
  }

  package init(statusCode: Int, body: Data) {
    self.statusCode = statusCode
    if let envelope = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: body) {
      self.message = envelope.error.message
      self.metadata = envelope.error.metadata?.stringMap
      self.kind = Self.classify(
        statusCode: statusCode,
        message: envelope.error.message,
        type: envelope.error.type,
        code: envelope.error.code
      )
    } else if let text = String(data: body, encoding: .utf8), !text.isEmpty {
      self.message = text
      self.kind = Self.classify(statusCode: statusCode, message: text, type: nil, code: nil)
      self.metadata = nil
    } else {
      self.message = "HTTP \(statusCode)"
      self.kind = Self.classify(statusCode: statusCode, message: "", type: nil, code: nil)
      self.metadata = nil
    }
  }

  package static func classify(
    statusCode: Int,
    message: String,
    type: String?,
    code: String?
  ) -> Kind {
    let lower = message.lowercased()
    if code == "context_length_exceeded" { return .contextLength }
    if code == "insufficient_quota" { return .insufficientCredits }
    if statusCode == 401 || lower.contains("api key") || lower.contains("unauthorized") {
      return .authentication
    }
    if statusCode == 403 { return .permission }
    if statusCode == 404 { return .notFound }
    if statusCode == 429 { return .rateLimit }
    if statusCode == 402 || lower.contains("credit") || lower.contains("quota") {
      return .insufficientCredits
    }
    if isContextLengthMessage(lower) {
      return .contextLength
    }
    if let type, let exact = Kind(rawValue: type) { return exact }
    if statusCode == 400 { return .invalidRequest }
    if (500...599).contains(statusCode) { return .server }
    return .other
  }

  private static func isContextLengthMessage(_ message: String) -> Bool {
    message.contains("context_length_exceeded")
      || message.contains("maximum context length")
      || message.contains("maximum context window")
      || message.contains("maximum context exceeded")
      || message.contains("context length exceeded")
      || message.contains("context window exceeded")
      || message.contains("exceeds the context window")
      || message.contains("too many tokens")
      || message.contains("reduce the length of the messages")
      || message.contains("input is too long")
  }
}

extension APIError: LocalizedError {
  package var errorDescription: String? {
    var parts = [message]
    if let statusCode { parts.append("(HTTP \(statusCode))") }
    return parts.joined(separator: " ")
  }
}

// MARK: - Wire envelopes

private struct OpenAIErrorEnvelope: Decodable {
  var error: Payload

  struct Payload: Decodable {
    var message: String
    var type: String?
    var code: String?
    var param: String?
    var metadata: JSONValue?
  }
}

extension JSONValue {
  fileprivate var stringMap: [String: String]? {
    guard case .object(let dict) = self else { return nil }
    var out: [String: String] = [:]
    for (k, v) in dict {
      switch v {
      case .string(let s): out[k] = s
      case .number(let n): out[k] = String(n)
      case .bool(let b): out[k] = String(b)
      default: out[k] = v.jsonText
      }
    }
    return out
  }
}
