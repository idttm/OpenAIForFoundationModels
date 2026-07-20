import Foundation
import FoundationModels
import OpenAIForFoundationModels

@main
struct OpenAIExample {
  static func main() async {
    let arguments = Array(CommandLine.arguments.dropFirst())
    let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""

    guard !apiKey.isEmpty else {
      fail(
        "Set OPENAI_API_KEY before running this example. "
          + "For shipping apps, use a server-side relay instead of embedding a key."
      )
    }

    if arguments.contains("--list") {
      await listModels(apiKey: apiKey, useCase: useCase(in: arguments))
      return
    }

    let modelID = value(after: "--model", in: arguments) ?? OpenAIModel.default.id
    let prompt =
      value(after: "--prompt", in: arguments)
      ?? "Explain why semantic streaming events are useful in one short paragraph."
    let reasoning = value(after: "--effort", in: arguments)
      .flatMap(OpenAIReasoning.Effort.init(rawValue:))
      .map(OpenAIReasoning.effort)

    let model = OpenAILanguageModel(
      name: modelID,
      auth: .apiKey(apiKey),
      reasoning: reasoning
    )
    let session = LanguageModelSession(model: model)

    print("OpenAI model: \(modelID)")
    print("---")

    do {
      for try await partial in session.streamResponse(to: prompt) {
        print("\u{001B}[2K\r\(partial.content)", terminator: "")
        fflush(stdout)
      }
      print("\n---")
      print("Complete.")
    } catch {
      fail("OpenAI request failed: \(error.localizedDescription)")
    }
  }

  private static func listModels(
    apiKey: String,
    useCase: ModelUseCase?
  ) async {
    do {
      let catalog = try OpenAIModelCatalog(auth: .apiKey(apiKey))
      let all = try await catalog.refresh()
      let visible =
        if let useCase {
          await catalog.models(for: useCase)
        } else {
          all
        }

      print("Models: \(visible.count) of \(all.count)")
      for model in visible {
        let features = model.uiConfiguration.featureLabels.joined(separator: ", ")
        print("\(model.id)\t[\(features)]")
      }
    } catch {
      fail("Could not load the OpenAI model catalog: \(error.localizedDescription)")
    }
  }

  private static func useCase(in arguments: [String]) -> ModelUseCase? {
    switch value(after: "--use-case", in: arguments) {
    case "chat": .chat
    case "agent": .agent
    case "reasoning": .reasoning
    case "multimodal": .multimodal
    case "structured": .structured
    default: nil
    }
  }

  private static func value(after flag: String, in arguments: [String]) -> String? {
    guard
      let index = arguments.firstIndex(of: flag),
      arguments.index(after: index) < arguments.endIndex
    else {
      return nil
    }
    return arguments[arguments.index(after: index)]
  }

  private static func fail(_ message: String) -> Never {
    fputs("\(message)\n", stderr)
    Foundation.exit(EXIT_FAILURE)
  }
}
