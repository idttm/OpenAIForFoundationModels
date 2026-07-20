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
            output: nil
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
