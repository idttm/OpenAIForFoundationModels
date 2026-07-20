import Foundation
import Security

/// Keychain storage for demo secrets (API key, proxy token).
///
/// - Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (no iCloud Keychain sync,
///   unavailable before first unlock).
/// - Never log returned values.
enum KeychainStore {
  private static let service = "com.openai.OpenAIDemo"

  enum Account: String {
    case apiKey = "openai-api-key"
    case proxyAppToken = "proxy-app-token"
  }

  static func load(_ account: Account) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account.rawValue,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  static func save(_ account: Account, value: String) throws {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      try delete(account)
      return
    }
    let data = Data(trimmed.utf8)
    // Delete-then-add so accessibility attribute is always reapplied.
    try? delete(account)
    let add: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account.rawValue,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    ]
    let status = SecItemAdd(add as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
  }

  static func delete(_ account: Account) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account.rawValue,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.unexpectedStatus(status)
    }
  }

  // MARK: - Convenience (API key)

  static func loadAPIKey() -> String? { load(.apiKey) }
  static func saveAPIKey(_ key: String) throws { try save(.apiKey, value: key) }
  static func deleteAPIKey() throws { try delete(.apiKey) }

  enum KeychainError: Error, LocalizedError {
    case unexpectedStatus(OSStatus)
    var errorDescription: String? {
      switch self {
      case .unexpectedStatus(let s): "Keychain error (\(s))"
      }
    }
  }
}
