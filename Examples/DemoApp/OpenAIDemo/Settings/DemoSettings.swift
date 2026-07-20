import Foundation
import Observation
import OpenAIForFoundationModels

@Observable
@MainActor
final class DemoSettings {
  var authKind: AuthKind = .apiKey
  var apiKey = ""
  var relayURL = "https://api.yourapp.com/openai/v1"
  var relayToken = ""
  var selectedModelID = OpenAIModel.default.id
  var reasoningChoice: ReasoningChoice = .automatic
  var enableWebSearch = false
  var enableClientTools = true
  var strictCapabilities = true
  var storeResponses = false
  var organizationID = ""
  var projectID = ""

  var hasCredential: Bool {
    switch authKind {
    case .apiKey:
      !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .relay:
      (try? baseURL()) != nil
    }
  }

  var accountScope: OpenAIAccountScope? {
    let organization = organizationID.trimmed.nilIfEmpty
    let project = projectID.trimmed.nilIfEmpty
    guard organization != nil || project != nil else { return nil }
    return OpenAIAccountScope(
      organizationID: organization,
      projectID: project
    )
  }

  func load() {
    apiKey = KeychainStore.load(.apiKey) ?? ""
    relayToken = KeychainStore.load(.proxyAppToken) ?? ""

    let defaults = UserDefaults.standard
    if let raw = defaults.string(forKey: Keys.authKind),
      let value = AuthKind(rawValue: raw)
    {
      authKind = value
    }
    relayURL = defaults.string(forKey: Keys.relayURL) ?? relayURL
    selectedModelID =
      defaults.string(forKey: Keys.selectedModelID) ?? selectedModelID
    if let raw = defaults.string(forKey: Keys.reasoning),
      let value = ReasoningChoice(rawValue: raw)
    {
      reasoningChoice = value
    }
    enableWebSearch = defaults.bool(forKey: Keys.enableWebSearch)
    enableClientTools =
      defaults.object(forKey: Keys.enableClientTools) as? Bool ?? true
    strictCapabilities =
      defaults.object(forKey: Keys.strictCapabilities) as? Bool ?? true
    storeResponses = defaults.bool(forKey: Keys.storeResponses)
    organizationID = defaults.string(forKey: Keys.organizationID) ?? ""
    projectID = defaults.string(forKey: Keys.projectID) ?? ""

    // Remove secrets from legacy defaults if an older demo ever wrote them.
    defaults.removeObject(forKey: "apiKey")
    defaults.removeObject(forKey: "relayToken")
    defaults.removeObject(forKey: "proxyAppToken")
  }

  func persist() {
    let defaults = UserDefaults.standard
    defaults.set(authKind.rawValue, forKey: Keys.authKind)
    defaults.set(relayURL, forKey: Keys.relayURL)
    defaults.set(selectedModelID, forKey: Keys.selectedModelID)
    defaults.set(reasoningChoice.rawValue, forKey: Keys.reasoning)
    defaults.set(enableWebSearch, forKey: Keys.enableWebSearch)
    defaults.set(enableClientTools, forKey: Keys.enableClientTools)
    defaults.set(strictCapabilities, forKey: Keys.strictCapabilities)
    defaults.set(storeResponses, forKey: Keys.storeResponses)
    defaults.set(organizationID, forKey: Keys.organizationID)
    defaults.set(projectID, forKey: Keys.projectID)
  }

  func saveAPIKey() throws {
    try KeychainStore.save(.apiKey, value: apiKey)
  }

  func clearAPIKey() throws {
    apiKey = ""
    try KeychainStore.delete(.apiKey)
  }

  func saveRelayToken() throws {
    try KeychainStore.save(.proxyAppToken, value: relayToken)
  }

  func clearRelayToken() throws {
    relayToken = ""
    try KeychainStore.delete(.proxyAppToken)
  }

  func authMode() throws -> AuthMode {
    switch authKind {
    case .apiKey:
      let key = apiKey.trimmed
      guard !key.isEmpty else { throw DemoError.missingAPIKey }
      return .apiKey(key)
    case .relay:
      _ = try baseURL()
      let token = relayToken.trimmed
      return .proxied(
        headers: token.isEmpty ? [:] : ["X-App-Token": token]
      )
    }
  }

  func baseURL() throws -> URL {
    switch authKind {
    case .apiKey:
      return OpenAILanguageModel.defaultBaseURL
    case .relay:
      guard let url = URL(string: relayURL.trimmed) else {
        throw DemoError.invalidRelayURL
      }
      guard EndpointPolicy.isAllowedProxyURL(url) else {
        throw DemoError.insecureRelayURL
      }
      return url
    }
  }

  private enum Keys {
    static let authKind = "authKind"
    static let relayURL = "relayURL"
    static let selectedModelID = "selectedModelID"
    static let reasoning = "reasoning"
    static let enableWebSearch = "enableWebSearch"
    static let enableClientTools = "enableClientTools"
    static let strictCapabilities = "strictCapabilities"
    static let storeResponses = "storeResponses"
    static let organizationID = "organizationID"
    static let projectID = "projectID"
  }
}

extension String {
  fileprivate var trimmed: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }

  fileprivate var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
