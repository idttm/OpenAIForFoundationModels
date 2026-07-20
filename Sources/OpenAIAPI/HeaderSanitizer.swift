import Foundation

/// Shared CR/LF strip + protected-header filter for extra / proxy header maps.
///
/// Used by ``OpenAIClient`` (request extras) and re-wrapped by
/// ``EndpointPolicy`` in the bridge module so both paths stay aligned.
package enum HeaderSanitizer: Sendable {
  /// Names that must never be set by untrusted header maps.
  package static let blockedNames: Set<String> = [
    "authorization",
    "host",
    "cookie",
    "set-cookie",
    "content-length",
    "transfer-encoding",
    "connection",
    "proxy-authorization",
    "proxy-authenticate",
    // Transport-managed
    "content-type",
    "user-agent",
    "openai-organization",
    "openai-project",
  ]

  package static func sanitize(_ headers: [String: String]) -> [String: String] {
    var out: [String: String] = [:]
    for (rawName, rawValue) in headers {
      let name = stripCRLF(rawName).trimmingCharacters(in: .whitespacesAndNewlines)
      let value = stripCRLF(rawValue)
      guard !name.isEmpty else { continue }
      if blockedNames.contains(name.lowercased()) { continue }
      out[name] = value
    }
    return out
  }

  private static func stripCRLF(_ s: String) -> String {
    s.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "")
  }
}
