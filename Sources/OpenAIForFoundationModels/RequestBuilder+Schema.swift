import Foundation
import FoundationModels
import OpenAIAPI

extension RequestBuilder {
  static func jsonSchema(from schema: GenerationSchema) throws -> JSONValue {
    guard let value = JSONValue.encoded(schema) else {
      throw unsupportedSchema("Could not encode the generation schema.")
    }
    return try sanitizeSchema(value)
  }

  static func applyStructuredOutput(
    _ schema: GenerationSchema,
    includeInPrompt: Bool,
    to request: inout ResponseRequest
  ) throws {
    request.text = TextConfiguration(
      format: .jsonSchema(
        name: "response",
        strict: true,
        schema: try jsonSchema(from: schema)
      )
    )

    guard includeInPrompt else { return }
    let hint = "Return one JSON object that matches the required schema."
    if let first = request.input.first,
      case .message(role: .developer, content: let content) = first
    {
      let existing = content.textValue
      request.input[0] = .developer(
        existing.isEmpty ? hint : existing + "\n\n" + hint
      )
    } else {
      request.input.insert(.developer(hint), at: 0)
    }
  }

  private static let allowedSchemaKeys: Set<String> = [
    "type", "properties", "required", "items", "enum", "const",
    "anyOf", "$ref", "$defs", "definitions",
    "description", "format", "additionalProperties",
  ]

  private static let mapValuedKeys: Set<String> = [
    "properties", "$defs", "definitions",
  ]

  private static let unsupportedCompositionKeys: Set<String> = [
    "allOf", "oneOf", "not", "dependentRequired", "dependentSchemas", "if", "then", "else",
  ]

  private static func unsupportedSchema(_ message: String) -> LanguageModelError {
    .unsupportedGenerationGuide(.init(schemaName: nil, debugDescription: message))
  }

  static func sanitizeSchema(_ value: JSONValue) throws -> JSONValue {
    switch value {
    case .object(let dictionary):
      if let key = unsupportedCompositionKeys.intersection(dictionary.keys).sorted().first {
        throw unsupportedSchema("OpenAI strict schemas do not support the \(key) keyword.")
      }
      let originallyRequired = Set(
        dictionary["required"]?.arrayValue?.compactMap(\.stringValue) ?? []
      )
      var result: [String: JSONValue] = [:]
      for (key, nested) in dictionary where allowedSchemaKeys.contains(key) {
        if mapValuedKeys.contains(key), case .object(let map) = nested {
          result[key] = .object(try map.mapValues(sanitizeSchema))
        } else if key == "enum" || key == "const" {
          result[key] = nested
        } else {
          result[key] = try sanitizeSchema(nested)
        }
      }

      if result["type"] == .string("object") {
        if case .object(var properties) = result["properties"] {
          for key in properties.keys where !originallyRequired.contains(key) {
            properties[key] = nullable(properties[key]!)
          }
          result["properties"] = .object(properties)
          result["required"] = .array(properties.keys.sorted().map(JSONValue.string))
        } else {
          result["required"] = .array([])
        }
        result["additionalProperties"] = .bool(false)
      }
      return .object(result)
    case .array(let values):
      return .array(try values.map(sanitizeSchema))
    default:
      return value
    }
  }

  private static func nullable(_ schema: JSONValue) -> JSONValue {
    guard !schema.allowsNull else { return schema }
    return .object([
      "anyOf": .array([
        schema,
        .object(["type": .string("null")]),
      ])
    ])
  }
}

extension JSONValue {
  fileprivate var arrayValue: [JSONValue]? {
    guard case .array(let values) = self else { return nil }
    return values
  }

  fileprivate var stringValue: String? {
    guard case .string(let value) = self else { return nil }
    return value
  }

  fileprivate var allowsNull: Bool {
    guard case .object(let object) = self else { return false }
    if object["type"] == .string("null") {
      return true
    }
    guard case .array(let variants) = object["anyOf"] else {
      return false
    }
    return variants.contains { $0.allowsNull }
  }
}
