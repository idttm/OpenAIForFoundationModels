import Foundation

enum DemoError: Error, LocalizedError {
  case missingAPIKey
  case invalidRelayURL
  case insecureRelayURL

  var errorDescription: String? {
    switch self {
    case .missingAPIKey:
      "Add an OpenAI API key in Settings or configure a secure relay."
    case .invalidRelayURL:
      "The relay URL is invalid."
    case .insecureRelayURL:
      "Relay URLs must use HTTPS. HTTP is allowed only for localhost."
    }
  }
}
