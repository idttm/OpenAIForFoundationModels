import Foundation
import FoundationModels
import Testing

@testable import OpenAIAPI
@testable import OpenAIForFoundationModels

struct ErrorMapperTests {
  @Test("Maps credential and quota failures to public OpenAI errors")
  func mapsOpenAIErrors() {
    let auth = ErrorMapper.map(
      APIError(kind: .authentication, message: "bad key", statusCode: 401)
    )
    #expect(auth as? OpenAIError == .missingOrInvalidCredential)

    let quota = ErrorMapper.map(
      APIError(kind: .insufficientCredits, message: "quota", statusCode: 429)
    )
    #expect(quota as? OpenAIError == .insufficientCredits)
  }

  @Test("Maps cancellation without wrapping it")
  func preservesCancellation() {
    #expect(ErrorMapper.map(CancellationError()) is CancellationError)
  }

  @Test("Sanitizes credential-shaped text")
  func sanitizesSecrets() {
    let fakeCredential = "sk-proj-" + String(repeating: "x", count: 26)
    let message =
      "Authorization: Bearer secret.token and key \(fakeCredential)"
    let sanitized = OpenAIError.sanitize(message)
    #expect(sanitized.contains("secret.token") == false)
    #expect(sanitized.contains("sk-proj") == false)
  }

  @Test("Schema validation context remains an HTTP invalid request")
  func schemaContextDoesNotMapToContextSizeExceeded() {
    let message =
      "Invalid schema for function 'current_time': In context=(), 'required' is required."
    let mapped = ErrorMapper.map(
      APIError(kind: .invalidRequest, message: message, statusCode: 400)
    )

    #expect(mapped as? OpenAIError == .http(status: 400, message: message))
  }
}
