import Foundation
import FoundationModels

// MARK: - Client-side tools (device-executed)

/// Arguments for ``ClockTool``.
@Generable
struct ClockToolArguments {
  @Guide(
    description:
      "IANA time zone id, e.g. America/New_York. Use null for device local time."
  )
  var timeZone: String?
}

/// Returns the current time — proves Foundation Models client `Tool` wiring.
struct ClockTool: Tool {
  let name = "current_time"
  let description = "Returns the current date and time for a time zone."

  func call(arguments: ClockToolArguments) async throws -> String {
    let tz: TimeZone
    let timeZone = arguments.timeZone?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if timeZone?.isEmpty != false {
      tz = .current
    } else {
      tz = TimeZone(identifier: timeZone ?? "") ?? .current
    }
    var cal = Calendar.current
    cal.timeZone = tz
    let formatter = DateFormatter()
    formatter.timeZone = tz
    formatter.dateStyle = .full
    formatter.timeStyle = .long
    return "\(formatter.string(from: .now)) (tz=\(tz.identifier))"
  }
}

@Generable
struct CalculatorArguments {
  @Guide(description: "First operand")
  var a: Double
  @Guide(description: "Second operand")
  var b: Double
  @Guide(description: "Operation: add, sub, mul, div")
  var op: String
}

/// Tiny calculator for multi-tool demos.
struct CalculatorTool: Tool {
  let name = "calculator"
  let description = "Performs basic arithmetic (add, sub, mul, div)."

  func call(arguments: CalculatorArguments) async throws -> String {
    let result: Double
    switch arguments.op.lowercased() {
    case "add", "+": result = arguments.a + arguments.b
    case "sub", "-": result = arguments.a - arguments.b
    case "mul", "*": result = arguments.a * arguments.b
    case "div", "/":
      guard arguments.b != 0 else { return "error: division by zero" }
      result = arguments.a / arguments.b
    default:
      return "error: unknown op \(arguments.op). Use add|sub|mul|div."
    }
    return String(result)
  }
}

enum SampleTools {
  static func all() -> [any Tool] {
    [ClockTool(), CalculatorTool()]
  }
}
