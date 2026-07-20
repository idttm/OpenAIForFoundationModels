import Foundation
import OpenAIAPI

/// Shared security policy for `baseURL` selection and proxy header maps.
///
/// Used by both the executor and catalog so API keys never leave for untrusted
/// hosts and untrusted header maps cannot overwrite security-critical fields.
public enum EndpointPolicy: Sendable {
  /// Hosts allowed when using ``AuthMode/apiKey`` (key leaves the device).
  public static let trustedAPIKeyHosts: Set<String> = [
    "api.openai.com"
  ]

  /// Header names that must never be set by ``AuthMode/proxied`` maps.
  ///
  /// Matches the client-side blocked set (auth, hop-by-hop, content-type, user-agent).
  public static let protectedHeaderNames: Set<String> = HeaderSanitizer.blockedNames

  /// Validate `baseURL` for the given auth mode.
  public static func validateBaseURL(_ url: URL, for auth: AuthMode) throws {
    guard let scheme = url.scheme?.lowercased(), let host = url.host, !host.isEmpty else {
      throw OpenAIError.invalidEndpoint("baseURL must include scheme and host.")
    }
    if url.user != nil || url.password != nil {
      throw OpenAIError.invalidEndpoint("baseURL must not include embedded credentials.")
    }

    switch auth {
    case .apiKey:
      guard scheme == "https" else {
        throw OpenAIError.invalidEndpoint(
          "API key auth requires an HTTPS OpenAI API base URL."
        )
      }
      guard trustedAPIKeyHosts.contains(host.lowercased()) else {
        throw OpenAIError.invalidEndpoint(
          "API key auth only allows api.openai.com; use AuthMode.proxied for a relay."
        )
      }
    case .proxied:
      guard isAllowedProxyURL(url) else {
        throw OpenAIError.invalidEndpoint(
          "Proxy baseURL must use HTTPS (or http://localhost / 127.0.0.1 / ::1 for local relays)."
        )
      }
    }
  }

  /// HTTPS anywhere, or HTTP only for loopback (local relay development).
  public static func isAllowedProxyURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased(), let host = url.host?.lowercased() else {
      return false
    }
    switch scheme {
    case "https":
      return true
    case "http":
      return host == "localhost" || host == "127.0.0.1" || host == "::1"
    default:
      return false
    }
  }

  /// Filter proxy headers: strip CR/LF, drop protected / hop-by-hop fields.
  public static func sanitizeProxyHeaders(_ headers: [String: String]) -> [String: String] {
    HeaderSanitizer.sanitize(headers)
  }
}
