import Testing

@testable import OpenAIForFoundationModels

struct ReasoningPolicyTests {
  private let reasoningModel = OpenAIModel(
    id: "reasoning-model",
    capabilities: .init(reasoning: true),
    reasoning: .init(
      supportedEfforts: [.high, .medium, .low],
      defaultEffort: .medium
    )
  )

  @Test("Fixed reasoning takes priority and clamps to a supported effort")
  func resolvesFixedReasoning() throws {
    let config = try ReasoningPolicy.resolve(
      fixed: .effort(.max),
      frameworkLevel: .light,
      model: reasoningModel,
      strict: true
    )
    #expect(config?.effort == .high)
    #expect(config?.summary == .auto)
  }

  @Test("Maps Foundation Models reasoning levels")
  func resolvesFrameworkReasoning() throws {
    let config = try ReasoningPolicy.resolve(
      fixed: nil,
      frameworkLevel: .deep,
      model: reasoningModel,
      strict: true
    )
    #expect(config?.effort == .high)
  }

  @Test("Strict mode rejects reasoning on an unsupported model")
  func rejectsUnsupportedReasoning() {
    #expect(throws: OpenAIError.self) {
      _ = try ReasoningPolicy.resolve(
        fixed: .effort(.medium),
        frameworkLevel: nil,
        model: OpenAIModel(id: "plain", capabilities: .unknown),
        strict: true
      )
    }
  }
}
