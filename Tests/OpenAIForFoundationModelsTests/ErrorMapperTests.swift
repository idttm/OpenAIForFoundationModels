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

  @Test("Maps refusal and incomplete responses to explicit public errors")
  func mapsRefusalAndIncomplete() {
    let refusal = ErrorMapper.map(
      APIError(kind: .refusal, message: "Safety refusal", statusCode: nil)
    )
    #expect(refusal as? OpenAIError == .refusal(message: "Safety refusal"))

    let incomplete = ErrorMapper.map(
      APIError(
        kind: .incomplete,
        message: "OpenAI response incomplete.",
        statusCode: nil,
        metadata: ["incomplete_reason": "max_output_tokens"]
      )
    )
    #expect(incomplete as? OpenAIError == .incomplete(reason: "max_output_tokens"))
  }

  @Test("Uses safe fallback when incomplete reason is absent")
  func mapsUnknownIncompleteReason() {
    let mapped = ErrorMapper.map(
      APIError(kind: .incomplete, message: "", statusCode: nil)
    )
    #expect(mapped as? OpenAIError == .incomplete(reason: "unknown"))
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
