import Foundation

/// Loosely-typed JSON for tool inputs/outputs, schemas, and provider config.
public enum JSONValue: Sendable, Hashable, Codable {
  case null
  case bool(Bool)
  case number(Double)
  case string(String)
  case array([JSONValue])
  case object([String: JSONValue])

  public init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if c.decodeNil() {
      self = .null
      return
    }
    if let v = try? c.decode(Bool.self) {
      self = .bool(v)
      return
    }
    if let v = try? c.decode(Double.self) {
      self = .number(v)
      return
    }
    if let v = try? c.decode(String.self) {
      self = .string(v)
      return
    }
    if let v = try? c.decode([JSONValue].self) {
      self = .array(v)
      return
    }
    if let v = try? c.decode([String: JSONValue].self) {
      self = .object(v)
      return
    }
    throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON value")
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .null: try c.encodeNil()
    case .bool(let v): try c.encode(v)
    case .number(let v): try c.encode(v)
    case .string(let v): try c.encode(v)
    case .array(let v): try c.encode(v)
    case .object(let v): try c.encode(v)
    }
  }

  public static func encoded(_ value: some Encodable) -> JSONValue? {
    guard let data = try? JSONEncoder().encode(value) else { return nil }
    return try? JSONDecoder().decode(JSONValue.self, from: data)
  }

  public static func parsed(_ json: String) -> JSONValue? {
    guard let data = json.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(JSONValue.self, from: data)
  }

  public var jsonText: String {
    guard let data = try? JSONEncoder().encode(self),
      let text = String(data: data, encoding: .utf8)
    else { return "null" }
    return text
  }
}

extension JSONValue: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral,
  ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral,
  ExpressibleByStringLiteral, ExpressibleByArrayLiteral,
  ExpressibleByDictionaryLiteral
{
  public init(nilLiteral: ()) { self = .null }
  public init(booleanLiteral value: Bool) { self = .bool(value) }
  public init(integerLiteral value: Int) { self = .number(Double(value)) }
  public init(floatLiteral value: Double) { self = .number(value) }
  public init(stringLiteral value: String) { self = .string(value) }
  public init(arrayLiteral elements: JSONValue...) { self = .array(elements) }
  public init(dictionaryLiteral elements: (String, JSONValue)...) {
    self = .object(.init(uniqueKeysWithValues: elements))
  }
}
