import Foundation
import FoundationModels
import Testing

@testable import OpenAIAPI
@testable import OpenAIForFoundationModels

private actor RecordingEventSink: GenerationEventSink {
  private(set) var count = 0
  private(set) var toolCallIDs: [String] = []
  private(set) var toolArgumentFragments: [String] = []

  func send(_ event: LanguageModelExecutorGenerationChannel.Event) async {
    count += 1
  }

  func sendToolCall(
    entryID: String,
    id: String,
    name: String,
    arguments: String,
    tokenCount: Int
  ) async {
    count += 1
    toolCallIDs.append(id)
    toolArgumentFragments.append(arguments)
  }
}

struct EventTranslatorTests {
  @Test("Translates metadata, reasoning, text, tools, and usage")
  func translatesSemanticEvents() async throws {
    let events = AsyncThrowingStream<ResponseStreamEvent, Error> { continuation in
      let decoder = JSONDecoder()
      let payloads = [
        #"{"type":"response.created","response":{"id":"resp_1","model":"gpt-5-mini"}}"#,
        #"{"type":"response.reasoning_summary_text.delta","delta":"Brief rationale"}"#,
        #"{"type":"response.output_text.delta","delta":"Hello"}"#,
        #"{"type":"response.output_item.added","output_index":0,"item":{"id":"fc_1","type":"function_call","call_id":"call_1","name":"clock","arguments":"{}"}}"#,
        #"{"type":"response.completed","response":{"id":"resp_1","status":"completed","usage":{"input_tokens":3,"output_tokens":2,"total_tokens":5,"input_tokens_details":{"cached_tokens":1},"output_tokens_details":{"reasoning_tokens":1}}}}"#,
      ]
      for payload in payloads {
        do {
          continuation.yield(
            try decoder.decode(
              ResponseStreamEvent.self,
              from: Data(payload.utf8)
            )
          )
        } catch {
          continuation.finish(throwing: error)
          return
        }
      }
      continuation.finish()
    }

    let sink = RecordingEventSink()
    try await EventTranslator(
      responseEntryID: "response",
      reasoningEntryID: "reasoning",
      toolCallsEntryID: "tools"
    ).translate(events, into: sink)

    #expect(await sink.count >= 6)
  }

  @Test("Keeps the OpenAI call ID while function arguments stream")
  func preservesCallIDAcrossArgumentDeltas() async throws {
    let events = AsyncThrowingStream<ResponseStreamEvent, Error> { continuation in
      let decoder = JSONDecoder()
      let payloads = [
        #"{"type":"response.output_item.added","output_index":0,"item":{"id":"fc_1","type":"function_call","call_id":"call_1","name":"current_time","arguments":""}}"#,
        #"{"type":"response.function_call_arguments.delta","item_id":"fc_1","output_index":0,"delta":"{\"timeZone\":"}"#,
        #"{"type":"response.function_call_arguments.delta","item_id":"fc_1","output_index":0,"delta":"\"America/Chicago\"}"}"#,
        #"{"type":"response.function_call_arguments.done","item_id":"fc_1","output_index":0,"arguments":"{\"timeZone\":\"America/Chicago\"}"}"#,
      ]
      for payload in payloads {
        do {
          continuation.yield(
            try decoder.decode(
              ResponseStreamEvent.self,
              from: Data(payload.utf8)
            )
          )
        } catch {
          continuation.finish(throwing: error)
          return
        }
      }
      continuation.finish()
    }

    let sink = RecordingEventSink()
    try await EventTranslator().translate(events, into: sink)

    #expect(await sink.toolCallIDs == ["call_1", "call_1"])
    #expect(
      await sink.toolArgumentFragments.joined()
        == #"{"timeZone":"America/Chicago"}"#
    )
  }

  @Test("Propagates a semantic failure")
  func propagatesFailure() async {
    let expected = APIError(kind: .rateLimit, message: "Slow down")
    let events = AsyncThrowingStream<ResponseStreamEvent, Error> { continuation in
      continuation.yield(.failed(expected))
      continuation.finish()
    }
    let sink = RecordingEventSink()

    do {
      try await EventTranslator().translate(events, into: sink)
      Issue.record("Expected the Responses stream failure.")
    } catch let error as APIError {
      #expect(error == expected)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}
