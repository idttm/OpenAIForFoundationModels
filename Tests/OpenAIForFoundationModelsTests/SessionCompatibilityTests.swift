import Foundation
import FoundationModels
import Testing

@testable import OpenAIAPI
@testable import OpenAIForFoundationModels

/// These fixtures exercise the Foundation Models runtime channel rather than
/// calling the executor directly.  The transport is immutable so tests can
/// run in parallel without sharing a response queue.
private enum SessionFixture: String, Hashable, Sendable {
  case text
  case structured

  var streamBody: String {
    switch self {
    case .text:
      return Self.sse([
        #"{"type":"response.created","response":{"id":"session-text","model":"gpt-test","status":"in_progress"}}"#,
        #"{"type":"response.output_text.delta","delta":"hello "}"#,
        #"{"type":"response.output_text.delta","delta":"foundation models"}"#,
        #"{"type":"response.completed","response":{"id":"session-text","model":"gpt-test","status":"completed","usage":{"input_tokens":2,"output_tokens":3,"total_tokens":5}}}"#,
      ])

    case .structured:
      return Self.sse([
        #"{"type":"response.created","response":{"id":"session-structured","model":"gpt-test","status":"in_progress"}}"#,
        #"{"type":"response.output_text.delta","delta":"{\"message\":\"structured\",\"count\":3}"}"#,
        #"{"type":"response.completed","response":{"id":"session-structured","model":"gpt-test","status":"completed","usage":{"input_tokens":2,"output_tokens":2,"total_tokens":4}}}"#,
      ])
    }
  }

  private static func sse(_ payloads: [String]) -> String {
    payloads.map { "data: \($0)\n\n" }.joined() + "data: [DONE]\n\n"
  }
}

private struct SessionFixtureTransport: HTTPTransport, Sendable {
  let fixture: SessionFixture

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    (Data(), response(for: request, contentType: "application/json"))
  }

  func bytes(
    for request: URLRequest
  ) async throws -> (AsyncThrowingStream<UInt8, Error>, URLResponse) {
    let body = fixture.streamBody
    let stream = AsyncThrowingStream<UInt8, Error> { continuation in
      for byte in body.utf8 {
        continuation.yield(byte)
      }
      continuation.finish()
    }
    return (stream, response(for: request, contentType: "text/event-stream"))
  }

  private func response(for request: URLRequest, contentType: String) -> URLResponse {
    HTTPURLResponse(
      url: request.url ?? URL(string: "http://127.0.0.1")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": contentType]
    )!
  }
}

private struct SessionExecutorConfiguration: Hashable, Sendable {
  let upstream: OpenAIExecutor.Configuration
  let fixture: SessionFixture
}

private struct SessionLanguageModel: LanguageModel, Sendable {
  typealias Executor = SessionExecutor

  let upstream: OpenAILanguageModel
  let fixture: SessionFixture

  var capabilities: LanguageModelCapabilities {
    upstream.capabilities
  }

  var executorConfiguration: SessionExecutorConfiguration {
    .init(upstream: upstream.executorConfiguration, fixture: fixture)
  }
}

private struct SessionExecutor: LanguageModelExecutor {
  typealias Model = SessionLanguageModel
  typealias Configuration = SessionExecutorConfiguration

  private let upstream: OpenAIExecutor

  init(configuration: Configuration) throws {
    upstream = OpenAIExecutor(
      configuration: configuration.upstream,
      transport: SessionFixtureTransport(fixture: configuration.fixture)
    )
  }

  func prewarm(model: Model, transcript: Transcript) {}

  func respond(
    to request: LanguageModelExecutorGenerationRequest,
    model: Model,
    streamingInto channel: LanguageModelExecutorGenerationChannel
  ) async throws {
    try await upstream.respond(
      to: request,
      model: model.upstream,
      streamingInto: channel
    )
  }
}

@Generable
private struct SessionCompatibilityAnswer {
  var message: String
  var count: Int
}

@Suite(.timeLimit(.minutes(1)))
struct SessionCompatibilityTests {
  @Test("Streams text through a real LanguageModelSession response channel")
  func streamsTextThroughSession() async throws {
    let session = LanguageModelSession(model: makeModel(.text))
    let stream = session.streamResponse(to: "Say hello")
    var snapshots: [String] = []

    for try await snapshot in stream {
      snapshots.append(snapshot.content)
    }

    #expect(!snapshots.isEmpty)
    #expect(snapshots.last == "hello foundation models")

    guard let response = latestResponse(in: session.transcript) else {
      Issue.record("Expected a response entry in the session transcript.")
      return
    }
    let model = try metadataValue(
      response.metadata,
      key: "openai.model",
      as: String.self
    )
    let responseID = try metadataValue(
      response.metadata,
      key: "openai.response_id",
      as: String.self
    )
    let totalTokens = try metadataValue(
      response.metadata,
      key: "openai.usage.total_tokens",
      as: Int.self
    )
    #expect(model == "gpt-test")
    #expect(responseID == "session-text")
    #expect(totalTokens == 5)
  }

  @Test("Decodes typed Generable output through a real LanguageModelSession")
  func decodesTypedOutputThroughSession() async throws {
    let session = LanguageModelSession(model: makeModel(.structured))
    let response = try await session.respond(
      to: "Return the structured answer",
      generating: SessionCompatibilityAnswer.self
    )

    #expect(response.content.message == "structured")
    #expect(response.content.count == 3)
  }

  private func makeModel(_ fixture: SessionFixture) -> SessionLanguageModel {
    let upstream = OpenAILanguageModel(
      name: OpenAIModel(
        id: "gpt-test",
        capabilities: .init(
          toolCalling: true,
          guidedGeneration: true
        )
      ),
      auth: .proxied(headers: [:]),
      baseURL: URL(string: "http://127.0.0.1/v1")!,
      timeout: 5
    )
    return SessionLanguageModel(upstream: upstream, fixture: fixture)
  }

  private func latestResponse(in transcript: Transcript) -> Transcript.Response? {
    transcript.compactMap { entry in
      guard case .response(let response) = entry else { return nil }
      return response
    }.last
  }

  private func metadataValue<Value: ConvertibleFromGeneratedContent>(
    _ metadata: [String: GeneratedContent],
    key: String,
    as type: Value.Type
  ) throws -> Value {
    guard let content = metadata[key] else {
      throw SessionCompatibilityError.missingMetadata(key)
    }
    return try content.value(type)
  }
}

private enum SessionCompatibilityError: Error {
  case missingMetadata(String)
}
