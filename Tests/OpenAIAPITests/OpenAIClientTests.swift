import Foundation
import Testing

@testable import OpenAIAPI

struct OpenAIClientTests {
  @Test("Lists models with OpenAI account headers and blocks header overrides")
  func listsModelsSecurely() async throws {
    let transport = RecordingTransport(
      .init(
        body:
          #"{"object":"list","data":[{"id":"gpt-5-mini","object":"model","created":1,"owned_by":"openai"}]}"#
      )
    )
    let client = OpenAIClient(
      configuration: .init(
        auth: .apiKey("sk-test"),
        organizationID: "org_config",
        projectID: "proj_config"
      ),
      transport: transport
    )

    let models = try await client.listModels(headers: [
      "Authorization": "Bearer attacker",
      "OpenAI-Project": "proj_attacker",
      "X-App-Trace": "trace\nsafe",
    ])

    #expect(models.map(\.id) == ["gpt-5-mini"])
    let request = try #require(await transport.requests.first)
    #expect(request.url?.path == "/v1/models")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
    #expect(request.value(forHTTPHeaderField: "OpenAI-Organization") == "org_config")
    #expect(request.value(forHTTPHeaderField: "OpenAI-Project") == "proj_config")
    #expect(request.value(forHTTPHeaderField: "X-App-Trace") == "tracesafe")
  }

  @Test("Forces streaming on the Responses endpoint")
  func streamsResponses() async throws {
    let transport = RecordingTransport(
      .init(
        body:
          "data: {\"type\":\"response.output_text.delta\",\"delta\":\"A\"}\n\n"
      )
    )
    let client = OpenAIClient(
      configuration: .init(auth: .apiKey("sk-test")),
      transport: transport
    )
    var events: [ResponseStreamEvent] = []
    for try await event in client.stream(
      ResponseRequest(
        model: "gpt-5-mini",
        input: [.user("Hello")],
        stream: false
      )
    ) {
      events.append(event)
    }

    #expect(events == [.outputTextDelta("A")])
    let request = try #require(await transport.requests.first)
    #expect(request.url?.path == "/v1/responses")
    let body = try #require(request.httpBody)
    let object = try #require(
      JSONSerialization.jsonObject(with: body) as? [String: Any]
    )
    #expect(object["stream"] as? Bool == true)
    #expect(object["store"] as? Bool == false)
  }

  @Test("Maps HTTP error bodies before decoding")
  func mapsHTTPError() async {
    let transport = RecordingTransport(
      .init(
        status: 401,
        body:
          #"{"error":{"message":"Incorrect API key","type":"authentication_error"}}"#
      )
    )
    let client = OpenAIClient(
      configuration: .init(auth: .apiKey("bad")),
      transport: transport
    )
    do {
      _ = try await client.listModels()
      Issue.record("Expected authentication failure.")
    } catch let error as APIError {
      #expect(error.kind == .authentication)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}
