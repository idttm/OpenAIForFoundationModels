import Foundation
import Testing

@testable import OpenAIAPI

struct APIErrorTests {
  @Test(
    "Classifies OpenAI error envelopes",
    arguments: [
      (
        401, #"{"error":{"message":"Incorrect API key","type":"invalid_request_error"}}"#,
        APIError.Kind.authentication
      ),
      (
        429, #"{"error":{"message":"Quota exhausted","code":"insufficient_quota"}}"#,
        .insufficientCredits
      ),
      (
        400, #"{"error":{"message":"Maximum context exceeded","code":"context_length_exceeded"}}"#,
        .contextLength
      ),
      (500, #"{"error":{"message":"Internal error","type":"server_error"}}"#, .server),
    ]
  )
  func classifies(status: Int, body: String, expected: APIError.Kind) {
    let error = APIError(statusCode: status, body: Data(body.utf8))
    #expect(error.kind == expected)
    #expect(error.statusCode == status)
  }

  @Test("Falls back to plain response text")
  func plainTextFallback() {
    let error = APIError(statusCode: 403, body: Data("Forbidden".utf8))
    #expect(error.kind == .permission)
    #expect(error.message == "Forbidden")
  }

  @Test("Schema validation context is not classified as transcript overflow")
  func schemaContextIsAnInvalidRequest() {
    let body = """
      {
        "error": {
          "message": "Invalid schema for function 'current_time': In context=(), 'required' is required.",
          "type": "invalid_request_error"
        }
      }
      """

    let error = APIError(statusCode: 400, body: Data(body.utf8))

    #expect(error.kind == .invalidRequest)
  }
}
