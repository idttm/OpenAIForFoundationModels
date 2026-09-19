import Foundation
import Testing

@testable import OpenAIAPI

struct ResponseStreamTests {
  @Test("Decodes semantic Responses stream events")
  func decodesEvents() throws {
    let decoder = JSONDecoder()

    let created = try decoder.decode(
      ResponseStreamEvent.self,
      from: Data(
        #"{"type":"response.created","response":{"id":"resp_1","model":"gpt-5-mini","status":"in_progress"}}"#
          .utf8
      )
    )
    #expect(
      created
        == .created(
          ResponseSummary(
            id: "resp_1",
            model: "gpt-5-mini",
            status: "in_progress",
            usage: nil,
            error: nil,
            output: nil,
            incompleteDetails: nil
          )
        )
    )

    let delta = try decoder.decode(
      ResponseStreamEvent.self,
      from: Data(
        #"{"type":"response.output_text.delta","delta":"Hello"}"#.utf8
      )
    )
    #expect(delta == .outputTextDelta("Hello"))

    let tool = try decoder.decode(
      ResponseStreamEvent.self,
      from: Data(
        #"{"type":"response.output_item.added","output_index":0,"item":{"id":"fc_1","type":"function_call","call_id":"call_1","name":"clock","arguments":""}}"#
          .utf8
      )
    )
    guard case .outputItemAdded(let index, let item) = tool else {
      Issue.record("Expected a function-call output item.")
      return
    }
    #expect(index == 0)
    #expect(item.callID == "call_1")
    #expect(item.name == "clock")
  }

  @Test(
    "Decodes flat and relay-wrapped streaming errors",
    arguments: [
      #"{"type":"error","code":"server_error","message":"Unavailable"}"#,
      #"{"type":"error","error":{"type":"server_error","message":"Unavailable"}}"#,
    ]
  )
  func decodesStreamErrors(payload: String) throws {
    let event = try JSONDecoder().decode(ResponseStreamEvent.self, from: Data(payload.utf8))
    guard case .failed(let error) = event else {
      Issue.record("Expected a semantic failure.")
      return
    }
    #expect(error.kind == .server)
    #expect(error.message == "Unavailable")
  }

  @Test("Treats a flat refusal.done event as a terminal failure")
  func decodesRefusalDone() throws {
    let event = try JSONDecoder().decode(
      ResponseStreamEvent.self,
      from: Data(
        #"{"type":"response.refusal.done","response_id":"resp_refusal","refusal":"I cannot help with that."}"#
          .utf8
      )
    )

    guard case .failed(let error) = event else {
      Issue.record("Expected refusal.done to fail the stream.")
      return
    }
    #expect(error.kind == .refusal)
    #expect(error.message == "I cannot help with that.")
    #expect(error.metadata?["response_id"] == "resp_refusal")
  }

  @Test("Treats refusal content in response.completed as a terminal failure")
  func decodesTerminalRefusal() throws {
    let event = try JSONDecoder().decode(
      ResponseStreamEvent.self,
      from: Data(
        """
        {
          "type": "response.completed",
          "response": {
            "id": "resp_terminal_refusal",
            "status": "completed",
            "output": [
              {"type":"message","content":[{"type":"refusal","refusal":"I cannot provide that."}]}
            ]
          }
        }
        """.utf8
      )
    )

    guard case .failed(let error) = event else {
      Issue.record("Expected terminal refusal content to fail the stream.")
      return
    }
    #expect(error.kind == .refusal)
    #expect(error.message == "I cannot provide that.")
  }

  @Test("Preserves response.incomplete reason metadata")
  func decodesIncompleteReason() throws {
    let event = try JSONDecoder().decode(
      ResponseStreamEvent.self,
      from: Data(
        #"{"type":"response.incomplete","response":{"id":"resp_incomplete","status":"incomplete","incomplete_details":{"reason":"max_output_tokens"}}}"#
          .utf8
      )
    )

    guard case .failed(let error) = event else {
      Issue.record("Expected response.incomplete to fail the stream.")
      return
    }
    #expect(error.kind == .incomplete)
    #expect(error.metadata?["incomplete_reason"] == "max_output_tokens")
    #expect(error.message.contains("max_output_tokens"))
  }

  @Test("An empty refusal cannot become successful blank output")
  func rejectsEmptyRefusal() throws {
    let event = try JSONDecoder().decode(
      ResponseStreamEvent.self,
      from: Data(
        #"{"type":"response.completed","response":{"output":[{"type":"message","content":[{"type":"refusal","refusal":""}]}]}}"#
          .utf8
      )
    )
    guard case .failed(let error) = event else {
      Issue.record("Expected an explicit refusal outcome.")
      return
    }
    #expect(error.kind == .refusal)
  }

  @Test("Aggregates text across every non-streaming output item")
  func aggregatesOutputText() throws {
    let response = try JSONDecoder().decode(
      ResponseObject.self,
      from: Data(
        """
        {
          "id": "resp_1",
          "status": "completed",
          "output": [
            {"type":"message","content":[{"type":"output_text","text":"Hello "}]},
            {"type":"message","content":[{"type":"output_text","text":"world"}]}
          ]
        }
        """.utf8
      )
    )
    #expect(response.outputText == "Hello world")
  }
}
