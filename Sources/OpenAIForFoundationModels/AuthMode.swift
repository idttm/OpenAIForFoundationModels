import Foundation

/// Identifies the credential the executor uses. `Hashable` so the framework can
/// cache one executor per unique `(model, auth)` pair.
///
/// Equality compares full credential material (required for executor cache).
/// ``description`` / ``debugDescription`` always redact secrets.
public enum AuthMode: Hashable, Sendable {
  /// Developer-supplied OpenAI API key. Bundled keys are extractable from a
  /// shipping app; for production, use ``proxied(headers:)``.
  ///
  /// Must be paired with `https://api.openai.com` (see ``EndpointPolicy``).
  case apiKey(String)

  /// Route requests through a developer-run proxy that adds the real credential
  /// server-side. `baseURL` points at the proxy; `headers` are sanitized and
  /// sent on every request (cannot override `Authorization`).
  case proxied(headers: [String: String])
}

extension AuthMode: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { debugDescription }

  public var debugDescription: String {
    switch self {
    case .apiKey(let key):
      return "AuthMode.apiKey(\(Self.redactSecret(key)))"
    case .proxied(let headers):
      let names = headers.keys.sorted().joined(separator: ", ")
      return "AuthMode.proxied(headerNames: [\(names)])"
    }
  }

  /// Whether this mode embeds a client-held secret (API key).
  public var embedsClientSecret: Bool {
    switch self {
    case .apiKey(let key): !key.isEmpty
    case .proxied: false
    }
  }

  /// Headers safe to send when using ``proxied`` (protected names stripped).
  public var sanitizedProxyHeaders: [String: String] {
    switch self {
    case .apiKey:
      return [:]
    case .proxied(let headers):
      return EndpointPolicy.sanitizeProxyHeaders(headers)
    }
  }

  private static func redactSecret(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "<empty>" }
    return "<redacted \(trimmed.count) chars>"
  }
}
