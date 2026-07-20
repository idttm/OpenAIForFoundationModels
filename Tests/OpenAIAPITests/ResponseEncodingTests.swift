import Foundation
import Testing

@testable import OpenAIAPI

struct ResponseEncodingTests {
  @Test("Encodes a Responses API request with strict tools and structured output")
  func encodesRequest() throws {
    let request = ResponseRequest(
      model: "gpt-5-mini",
      input: [
        .developer("Be concise."),
        .user("Weather in Chicago?"),
        .functionCall(
          id: "item_1",
          callID: "call_1",
          name: "weather",
          arguments: #"{"city":"Chicago"}"#
        ),
        .functionCallOutput(callID: "call_1", output: #"{"temp":72}"#),
      ],
      store: false,
      maxOutputTokens: 256,
      tools: [
        .function(
          ToolDefinition(
            name: "weather",
            description: "Get weather",
            parameters: [
              "type": "object",
              "properties": ["city": ["type": "string"]],
              "required": ["city"],
              "additionalProperties": false,
            ]
          )
        ),
        .webSearch,
      ],
      toolChoice: .function(name: "weather"),
      text: TextConfiguration(
        format: .jsonSchema(
          name: "forecast",
          strict: true,
          schema: [
            "type": "object",
            "properties": ["temp": ["type": "number"]],
            "required": ["temp"],
            "additionalProperties": false,
          ]
        )
      ),
      reasoning: .init(effort: .medium, summary: .auto),
      safetyIdentifier: "hashed-user",
      promptCacheKey: "weather-v1"
    )

    let data = try JSONEncoder().encode(request)
    let object = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    #expect(object["model"] as? String == "gpt-5-mini")
    #expect(object["store"] as? Bool == false)
    #expect(object["max_output_tokens"] as? Int == 256)
    #expect(object["safety_identifier"] as? String == "hashed-user")

    let tools = try #require(object["tools"] as? [[String: Any]])
    #expect(tools.count == 2)
    #expect(tools[0]["type"] as? String == "function")
    #expect(tools[0]["name"] as? String == "weather")
    #expect(tools[0]["strict"] as? Bool == true)
    #expect(tools[1]["type"] as? String == "web_search")

    let text = try #require(object["text"] as? [String: Any])
    let format = try #require(text["format"] as? [String: Any])
    #expect(format["type"] as? String == "json_schema")
    #expect(format["name"] as? String == "forecast")
  }

  @Test("Round trips JSON values and response input item variants")
  func roundTripsValues() throws {
    let value: JSONValue = [
      "ok": true,
      "count": 2,
      "items": ["a", nil],
    ]
    let decoded = try JSONDecoder().decode(
      JSONValue.self,
      from: JSONEncoder().encode(value)
    )
    #expect(decoded == value)

    let item = ResponseInputItem.message(
      role: .user,
      content: .parts([
        .text("Describe this"),
        .imageURL("data:image/png;base64,AA==", detail: "low"),
      ])
    )
    let roundTrip = try JSONDecoder().decode(
      ResponseInputItem.self,
      from: JSONEncoder().encode(item)
    )
    #expect(roundTrip == item)
  }
}
