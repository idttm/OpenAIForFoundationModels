import Foundation
import FoundationModels
import OpenAIAPI

/// Pure translation from a Foundation Models generation request to OpenAI's
/// Responses API.
enum RequestBuilder {
  struct Built: Sendable {
    var request: ResponseRequest
    var isStructured: Bool
  }

  static func build(
    from request: LanguageModelExecutorGenerationRequest,
    model: OpenAIModel,
    fixedReasoning: OpenAIReasoning? = nil,
    builtInTools: Set<OpenAIBuiltInTool> = [],
    storeResponses: Bool = false,
    safetyIdentifier: String? = nil,
    promptCacheKey: String? = nil,
    strictCapabilities: Bool = true
  ) throws -> Built {
    var input = try transcriptInput(from: request.transcript)

    let functionTools = try resolveTools(
      request.enabledToolDefinitions,
      model: model,
      strict: strictCapabilities
    )
    let tools = responseTools(
      functions: functionTools,
      builtIns: builtInTools,
      model: model,
      strict: strictCapabilities
    )

    input = try applyVisionPolicy(
      input,
      model: model,
      strict: strictCapabilities
    )

    let reasoning = try ReasoningPolicy.resolve(
      fixed: fixedReasoning,
      frameworkLevel: frameworkReasoning(from: request.contextOptions),
      model: model,
      strict: strictCapabilities
    )

    var response = ResponseRequest(
      model: model.id,
      input: input,
      stream: true,
      store: storeResponses,
      maxOutputTokens: request.generationOptions.maximumResponseTokens,
      tools: tools.isEmpty ? nil : tools,
      toolChoice: functionTools.isEmpty
        ? nil
        : toolChoice(for: request.generationOptions.toolCallingMode),
      reasoning: reasoning,
      parallelToolCalls: functionTools.isEmpty ? nil : true,
      safetyIdentifier: safetyIdentifier,
      promptCacheKey: promptCacheKey
    )

    applySampling(request.generationOptions, to: &response, model: model)

    let isStructured = request.schema != nil
    if let schema = request.schema {
      try applySchemaCapability(
        schema,
        includeInPrompt: request.contextOptions.includeSchemaInPrompt ?? true,
        model: model,
        strict: strictCapabilities,
        to: &response
      )
    }

    return Built(request: response, isStructured: isStructured)
  }

  private static func transcriptInput(
    from transcript: Transcript
  ) throws -> [ResponseInputItem] {
    var input: [ResponseInputItem] = []
    var developerParts: [String] = []

    for entry in transcript {
      switch entry {
      case .instructions(let instructions):
        let value = text(of: instructions.segments)
        if !value.isEmpty { developerParts.append(value) }

      case .prompt(let prompt):
        input.append(
          .message(
            role: .user,
            content: try inputContent(from: prompt.segments)
          )
        )

      case .response(let response):
        input.append(.assistant(text(of: response.segments)))

      case .reasoning:
        // Responses reasoning items are provider-authored opaque values. The
        // Foundation Models transcript exposes rendered reasoning segments, not
        // the encrypted item needed for lossless replay, so they are omitted.
        break

      case .toolCalls(let calls):
        for call in calls {
          input.append(
            .functionCall(
              id: nil,
              callID: call.id,
              name: call.toolName,
              arguments: call.arguments.jsonString
            )
          )
        }

      case .toolOutput(let output):
        input.append(
          .functionCallOutput(
            callID: output.id,
            output: text(of: output.segments)
          )
        )

      @unknown default:
        break
      }
    }

    if !developerParts.isEmpty {
      input.insert(
        .developer(developerParts.joined(separator: "\n\n")),
        at: 0
      )
    }
    return input
  }

  private static func resolveTools(
    _ definitions: [Transcript.ToolDefinition],
    model: OpenAIModel,
    strict: Bool
  ) throws -> [ToolDefinition] {
    guard !definitions.isEmpty else { return [] }
    guard model.capabilities.toolCalling else {
      if strict {
        throw OpenAIError.unsupportedCapability(
          "\(model.id) does not advertise function calling."
        )
      }
      return []
    }
    return definitions.map {
      ToolDefinition(
        name: $0.name,
        description: $0.description,
        parameters: jsonSchema(from: $0.parameters),
        strict: true
      )
    }
  }

  private static func responseTools(
    functions: [ToolDefinition],
    builtIns: Set<OpenAIBuiltInTool>,
    model: OpenAIModel,
    strict: Bool
  ) -> [ResponseTool] {
    var result = functions.map(ResponseTool.function)
    if builtIns.contains(.webSearch),
      model.capabilities.webSearch || !strict
    {
      result.append(.webSearch)
    }
    return result
  }

  private static func applyVisionPolicy(
    _ input: [ResponseInputItem],
    model: OpenAIModel,
    strict: Bool
  ) throws -> [ResponseInputItem] {
    let containsImage = input.contains { item in
      guard case .message(_, .parts(let parts)) = item else { return false }
      return parts.contains {
        if case .imageURL = $0 { return true }
        return false
      }
    }
    guard containsImage, !model.capabilities.vision else { return input }
    if strict {
      throw OpenAIError.unsupportedCapability(
        "\(model.id) does not advertise image input."
      )
    }
    return input.map(stripImages)
  }

  private static func applySchemaCapability(
    _ schema: GenerationSchema,
    includeInPrompt: Bool,
    model: OpenAIModel,
    strict: Bool,
    to request: inout ResponseRequest
  ) throws {
    guard model.capabilities.guidedGeneration else {
      if strict {
        throw LanguageModelError.unsupportedGenerationGuide(
          .init(
            schemaName: nil,
            debugDescription:
              "\(model.id) does not advertise Responses API Structured Outputs."
          )
        )
      }
      return
    }
    applyStructuredOutput(
      schema,
      includeInPrompt: includeInPrompt,
      to: &request
    )
  }

  private static func toolChoice(
    for mode: GenerationOptions.ToolCallingMode?
  ) -> ToolChoice? {
    guard let mode else { return nil }
    switch mode.kind {
    case .required:
      return ToolChoice.required
    case .disallowed:
      return ToolChoice.none
    case .allowed:
      return nil
    @unknown default:
      return nil
    }
  }

  private static func frameworkReasoning(
    from options: ContextOptions
  ) -> ReasoningPolicy.FrameworkReasoningLevel? {
    switch options.reasoningLevel {
    case .none:
      return ReasoningPolicy.FrameworkReasoningLevel.none
    case .light:
      return .light
    case .moderate:
      return .moderate
    case .deep:
      return .deep
    case .custom(let value):
      return .custom(value)
    @unknown default:
      return nil
    }
  }

  private static func applySampling(
    _ options: GenerationOptions,
    to request: inout ResponseRequest,
    model: OpenAIModel
  ) {
    guard model.capabilities.sampling else { return }
    request.temperature = options.temperature
    guard let mode = options.samplingMode else { return }
    switch mode.kind {
    case .greedy:
      request.temperature = 0
    case .randomTopK:
      // Responses does not expose top_k.
      break
    case .randomProbabilityThreshold(let probability, _):
      request.topP = probability
    @unknown default:
      break
    }
  }
}
