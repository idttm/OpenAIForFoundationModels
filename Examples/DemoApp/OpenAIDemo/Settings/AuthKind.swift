import Foundation

enum AuthKind: String, CaseIterable, Identifiable {
  case apiKey = "API key"
  case relay = "Secure relay"

  var id: Self { self }
}
