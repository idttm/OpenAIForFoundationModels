import Foundation

/// OpenAI-specific errors that do not map cleanly onto Foundation Models
/// `LanguageModelError` cases. Apps should only see this type (or
/// `LanguageModelError`) — never package-internal `APIError`.
public enum OpenAIError: Error, Sendable, Equatable {
  /// API key missing or rejected.
  case missingOrInvalidCredential
  /// Project has no remaining quota or billing is required.
  case insufficientCredits
  /// Requested capability (reasoning, structured output, tools, vision, …) is not supported.
  case unsupportedCapability(String)
  /// Base URL / auth combination is not allowed.
  case invalidEndpoint(String)
  /// HTTP failure with status (user-safe message; no raw secrets).
  case http(status: Int, message: String)
  /// Stream finished without usable content (malformed SSE / empty body).
  case emptyStream
  /// Resource missing (404).
  case notFound(message: String)
  /// Permission denied (403).
  case permission(message: String)
  /// Generic upstream failure with a message.
  case upstream(message: String)
  /// The model refused to fulfill the request.
  case refusal(message: String)
  /// The model stopped before completing the response.
  case incomplete(reason: String)
}

extension OpenAIError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .missingOrInvalidCredential:
      return "OpenAI API key is missing or invalid."
    case .insufficientCredits:
      return "The OpenAI project has insufficient quota or requires billing."
    case .unsupportedCapability(let detail):
      return "Unsupported capability: \(detail)"
    case .invalidEndpoint(let detail):
      return "Invalid endpoint: \(detail)"
    case .http(let status, let message):
      return "\(Self.sanitize(message)) (HTTP \(status))"
    case .emptyStream:
      return "Model stream ended without content (empty or undecodable response)."
    case .notFound(let message):
      return Self.sanitize(message)
    case .permission(let message):
      return Self.sanitize(message)
    case .upstream(let message):
      return Self.sanitize(message)
    case .refusal(let message):
      let safe = Self.sanitize(message)
      return safe.isEmpty
        ? "The model refused the request."
        : "The model refused the request: \(safe)"
    case .incomplete(let reason):
      let safe = Self.sanitize(reason)
      return safe.isEmpty
        ? "The model response was incomplete (unknown reason)."
        : "The model response was incomplete (\(safe))."
    }
  }

  /// Strip credential-shaped substrings from upstream text.
  public static func sanitize(_ message: String) -> String {
    var s = message
    let patterns = [
      #"(?i)sk-[a-z0-9_-]{10,}"#,
      #"(?i)bearer\s+[a-z0-9._\-]+"#,
      #"(?i)x-app-token\s*[:=]\s*\S+"#,
    ]
    for p in patterns {
      if let re = try? NSRegularExpression(pattern: p) {
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        s = re.stringByReplacingMatches(in: s, range: range, withTemplate: "<redacted>")
      }
    }
    return s
  }
}
