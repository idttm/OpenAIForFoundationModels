import Foundation
import FoundationModels
import OpenAIAPI

extension RequestBuilder {
  static func jsonSchema(from schema: GenerationSchema) -> JSONValue {
    guard let value = JSONValue.encoded(schema) else {
      return .object(["type": .string("object")])
    }
    return sanitize(value)
  }

  static func applyStructuredOutput(
    _ schema: GenerationSchema,
    includeInPrompt: Bool,
    to request: inout ResponseRequest
  ) {
    request.text = TextConfiguration(
      format: .jsonSchema(
        name: "response",
        strict: true,
        schema: jsonSchema(from: schema)
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
    "anyOf", "allOf", "oneOf", "$ref", "$defs", "definitions",
    "description", "format", "additionalProperties",
  ]

  private static let mapValuedKeys: Set<String> = [
    "properties", "$defs", "definitions",
  ]

  private static func sanitize(_ value: JSONValue) -> JSONValue {
    switch value {
    case .object(let dictionary):
      let originallyRequired = Set(
        dictionary["required"]?.arrayValue?.compactMap(\.stringValue) ?? []
      )
      var result: [String: JSONValue] = [:]
      for (key, nested) in dictionary where allowedSchemaKeys.contains(key) {
        if mapValuedKeys.contains(key), case .object(let map) = nested {
          result[key] = .object(map.mapValues(sanitize))
        } else {
          result[key] = sanitize(nested)
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
      return .array(values.map(sanitize))
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
