import Foundation

/// Request body for `POST /v1/responses`.
package struct ResponseRequest: Sendable, Codable {
  package var model: String
  package var input: [ResponseInputItem]
  package var stream: Bool
  package var store: Bool
  package var maxOutputTokens: Int?
  package var temperature: Double?
  package var topP: Double?
  package var tools: [ResponseTool]?
  package var toolChoice: ToolChoice?
  package var text: TextConfiguration?
  package var reasoning: ReasoningConfig?
  package var parallelToolCalls: Bool?
  package var safetyIdentifier: String?
  package var promptCacheKey: String?

  package init(
    model: String,
    input: [ResponseInputItem],
    stream: Bool = true,
    store: Bool = false,
    maxOutputTokens: Int? = nil,
    temperature: Double? = nil,
    topP: Double? = nil,
    tools: [ResponseTool]? = nil,
    toolChoice: ToolChoice? = nil,
    text: TextConfiguration? = nil,
    reasoning: ReasoningConfig? = nil,
    parallelToolCalls: Bool? = nil,
    safetyIdentifier: String? = nil,
    promptCacheKey: String? = nil
  ) {
    self.model = model
    self.input = input
    self.stream = stream
    self.store = store
    self.maxOutputTokens = maxOutputTokens
    self.temperature = temperature
    self.topP = topP
    self.tools = tools
    self.toolChoice = toolChoice
    self.text = text
    self.reasoning = reasoning
    self.parallelToolCalls = parallelToolCalls
    self.safetyIdentifier = safetyIdentifier
    self.promptCacheKey = promptCacheKey
  }

  private enum CodingKeys: String, CodingKey {
    case model, input, stream, store, temperature, tools, text, reasoning
    case maxOutputTokens = "max_output_tokens"
    case topP = "top_p"
    case toolChoice = "tool_choice"
    case parallelToolCalls = "parallel_tool_calls"
    case safetyIdentifier = "safety_identifier"
    case promptCacheKey = "prompt_cache_key"
  }
}

package enum ResponseTool: Sendable, Hashable, Codable {
  case function(ToolDefinition)
  case webSearch

  package init(from decoder: Decoder) throws {
    let probe = try decoder.container(keyedBy: TypeKey.self)
    switch try probe.decode(String.self, forKey: .type) {
    case "function":
      self = .function(try ToolDefinition(from: decoder))
    case "web_search":
      self = .webSearch
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .type,
        in: probe,
        debugDescription: "Unsupported Responses tool"
      )
    }
  }

  package func encode(to encoder: Encoder) throws {
    switch self {
    case .function(let definition):
      try definition.encode(to: encoder)
    case .webSearch:
      var c = encoder.container(keyedBy: TypeKey.self)
      try c.encode("web_search", forKey: .type)
    }
  }

  private enum TypeKey: String, CodingKey { case type }
}

package struct TextConfiguration: Sendable, Hashable, Codable {
  package var format: ResponseFormat

  package init(format: ResponseFormat) {
    self.format = format
  }
}

package enum ResponseFormat: Sendable, Hashable, Codable {
  case jsonObject
  case jsonSchema(name: String, strict: Bool, schema: JSONValue)

  private enum CodingKeys: String, CodingKey {
    case type, name, strict, schema
  }

  package init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    switch try c.decode(String.self, forKey: .type) {
    case "json_object":
      self = .jsonObject
    case "json_schema":
      self = .jsonSchema(
        name: try c.decode(String.self, forKey: .name),
        strict: try c.decodeIfPresent(Bool.self, forKey: .strict) ?? true,
        schema: try c.decode(JSONValue.self, forKey: .schema)
      )
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .type,
        in: c,
        debugDescription: "Unsupported text format"
      )
    }
  }

  package func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .jsonObject:
      try c.encode("json_object", forKey: .type)
    case .jsonSchema(let name, let strict, let schema):
      try c.encode("json_schema", forKey: .type)
      try c.encode(name, forKey: .name)
      try c.encode(strict, forKey: .strict)
      try c.encode(schema, forKey: .schema)
    }
  }
}
