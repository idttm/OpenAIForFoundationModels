import Foundation
import FoundationModels
import Testing

@testable import OpenAIAPI
@testable import OpenAIForFoundationModels

struct RequestBuilderTests {
  private let fullModel = OpenAIModel(
    id: "gpt-test",
    capabilities: .init(
      toolCalling: true,
      guidedGeneration: true,
      vision: true,
      reasoning: true,
      sampling: true,
      webSearch: true
    ),
    reasoning: .init(
      supportedEfforts: [.high, .medium, .low],
      defaultEffort: .medium
    ),
    isCatalogBacked: true
  )

  @Test("Maps instructions, conversation history, storage, and request metadata")
  func mapsTranscript() throws {
    let request = generationRequest(entries: [
      instructions("Be concise."),
      prompt("Hello"),
      response("Hi."),
      prompt("What can you do?"),
    ])
    let built = try RequestBuilder.build(
      from: request,
      model: fullModel,
      storeResponses: true,
      safetyIdentifier: "user-hash",
      promptCacheKey: "chat-v1"
    )

    #expect(built.request.model == "gpt-test")
    #expect(built.request.stream)
    #expect(built.request.store)
    #expect(built.request.safetyIdentifier == "user-hash")
    #expect(built.request.promptCacheKey == "chat-v1")
    #expect(
      built.request.input.compactMap(\.messageRole) == [
        .developer, .user, .assistant, .user,
      ])
    #expect(built.request.input.first?.messageContent?.textValue == "Be concise.")
  }

  @Test("Maps function definitions, tool calls, outputs, and built-in web search")
  func mapsTools() throws {
    let definition = try toolDefinition(name: "clock")
    let content = try GeneratedContent(json: #"{"zone":"UTC"}"#)
    let request = generationRequest(
      entries: [
        prompt("What time is it?"),
        .toolCalls(
          Transcript.ToolCalls([
            .init(id: "call_1", toolName: "clock", arguments: content)
          ])
        ),
        .toolOutput(
          Transcript.ToolOutput(
            id: "call_1",
            toolName: "clock",
            segments: [textSegment("12:00 UTC")]
          )
        ),
      ],
      tools: [definition]
    )

    let built = try RequestBuilder.build(
      from: request,
      model: fullModel,
      builtInTools: [.webSearch]
    )
    #expect(built.request.tools?.count == 2)
    #expect(built.request.parallelToolCalls == true)
    guard
      case .functionCall(_, let callID, let name, let arguments) =
        built.request.input[1]
    else {
      Issue.record("Expected a Responses function_call input item.")
      return
    }
    #expect(callID == "call_1")
    #expect(name == "clock")
    #expect(arguments.contains("UTC"))
    #expect(
      built.request.input[2]
        == .functionCallOutput(callID: "call_1", output: "12:00 UTC")
    )
  }

  @Test("Uses Responses Structured Outputs and developer schema hint")
  func mapsStructuredOutput() throws {
    let schema = try emptySchema()
    let built = try RequestBuilder.build(
      from: generationRequest(entries: [prompt("Return a value")], schema: schema),
      model: fullModel
    )
    #expect(built.isStructured)
    #expect(built.request.text != nil)
    #expect(
      built.request.input.first?.messageContent?.textValue
        .contains("required schema") == true
    )
  }

  @Test("Converts optional properties to OpenAI strict nullable properties")
  func mapsOptionalPropertiesForStrictSchemas() throws {
    let schema = try GenerationSchema(
      root: DynamicGenerationSchema(
        name: "Arguments",
        properties: [
          .init(
            name: "timeZone",
            description: "IANA time zone or null.",
            schema: DynamicGenerationSchema(type: String.self),
            isOptional: true
          )
        ]
      ),
      dependencies: []
    )

    let value = RequestBuilder.jsonSchema(from: schema)
    guard case .object(let root) = value,
      case .array(let required) = root["required"],
      case .object(let properties) = root["properties"],
      case .object(let timeZone) = properties["timeZone"],
      case .array(let alternatives) = timeZone["anyOf"]
    else {
      Issue.record("Expected an OpenAI strict object schema.")
      return
    }

    #expect(required == [.string("timeZone")])
    #expect(
      alternatives.contains {
        guard case .object(let schema) = $0 else { return false }
        return schema["type"] == .string("string")
      }
    )
    #expect(
      alternatives.contains {
        guard case .object(let schema) = $0 else { return false }
        return schema["type"] == .string("null")
      }
    )
    #expect(root["additionalProperties"] == .bool(false))
  }

  @Test("Strict mode rejects tools on an unsupported deployment")
  func rejectsUnsupportedTools() throws {
    let request = generationRequest(
      entries: [prompt("Use a tool")],
      tools: [try toolDefinition()]
    )
    #expect(throws: OpenAIError.self) {
      _ = try RequestBuilder.build(
        from: request,
        model: OpenAIModel(id: "plain", capabilities: .unknown),
        strictCapabilities: true
      )
    }
  }

  @Test("Applies sampling only when the model supports it")
  func appliesSampling() throws {
    var options = GenerationOptions()
    options.temperature = 0.25
    let built = try RequestBuilder.build(
      from: generationRequest(
        entries: [prompt("Hello")],
        generationOptions: options
      ),
      model: fullModel
    )
    #expect(built.request.temperature == 0.25)
  }

  private func generationRequest(
    entries: [Transcript.Entry],
    tools: [Transcript.ToolDefinition] = [],
    schema: GenerationSchema? = nil,
    generationOptions: GenerationOptions = GenerationOptions()
  ) -> LanguageModelExecutorGenerationRequest {
    LanguageModelExecutorGenerationRequest(
      id: UUID(),
      transcript: Transcript(entries: entries),
      enabledTools: tools,
      schema: schema,
      generationOptions: generationOptions,
      contextOptions: ContextOptions(),
      metadata: [:] as [String: String]
    )
  }

  private func textSegment(_ value: String) -> Transcript.Segment {
    .text(Transcript.TextSegment(content: value))
  }

  private func instructions(_ value: String) -> Transcript.Entry {
    .instructions(
      Transcript.Instructions(
        segments: [textSegment(value)],
        toolDefinitions: []
      )
    )
  }

  private func prompt(_ value: String) -> Transcript.Entry {
    .prompt(
      Transcript.Prompt(
        segments: [textSegment(value)],
        options: GenerationOptions()
      )
    )
  }

  private func response(_ value: String) -> Transcript.Entry {
    .response(Transcript.Response(segments: [textSegment(value)]))
  }

  private func emptySchema() throws -> GenerationSchema {
    try GenerationSchema(
      root: DynamicGenerationSchema(name: "Result", properties: []),
      dependencies: []
    )
  }

  private func toolDefinition(
    name: String = "clock"
  ) throws -> Transcript.ToolDefinition {
    try Transcript.ToolDefinition(
      name: name,
      description: "Returns a time.",
      parameters: emptySchema()
    )
  }
}
