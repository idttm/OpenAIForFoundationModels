import Foundation
import Testing

@testable import OpenAIForFoundationModels

struct EndpointPolicyTests {
  @Test(
    "API keys only travel to the official HTTPS host",
    arguments: [
      "http://api.openai.com/v1",
      "https://api.openai.com.evil.example/v1",
      "https://user:pass@api.openai.com/v1",
      "https://example.com/v1",
    ]
  )
  func rejectsUntrustedAPIKeyEndpoint(rawURL: String) {
    let url = URL(string: rawURL)!
    #expect(throws: OpenAIError.self) {
      try EndpointPolicy.validateBaseURL(url, for: .apiKey("sk-test"))
    }
  }

  @Test(
    "Allows secure or loopback relays",
    arguments: [
      "https://relay.example/v1",
      "http://localhost:8787/v1",
      "http://127.0.0.1:8787/v1",
    ]
  )
  func acceptsRelay(rawURL: String) throws {
    let url = URL(string: rawURL)!
    #expect(throws: Never.self) {
      try EndpointPolicy.validateBaseURL(url, for: .proxied(headers: [:]))
    }
  }

  @Test("Sanitizes proxy headers and redacts descriptions")
  func sanitizesHeaders() {
    let auth = AuthMode.proxied(headers: [
      "Authorization": "Bearer attacker",
      "OpenAI-Project": "wrong",
      "X-App-Token": "value\r\nsafe",
    ])
    #expect(auth.sanitizedProxyHeaders == ["X-App-Token": "valuesafe"])
    #expect(auth.description.contains("value") == false)

    let key = AuthMode.apiKey("sk-proj-supersecret")
    #expect(key.description.contains("supersecret") == false)
    #expect(key.embedsClientSecret == true)
  }
}
