import Foundation
import Testing

@testable import OpenAIForFoundationModels

struct OpenAIModelTests {
  @Test(
    "Infers conservative family capabilities",
    arguments: [
      ("gpt-5-mini", true, true, false),
      ("gpt-4o-mini", false, true, true),
      ("o4-mini", true, true, false),
      ("text-embedding-3-large", false, false, false),
      ("custom-unknown", false, false, false),
    ]
  )
  func infersCapabilities(
    id: String,
    reasoning: Bool,
    vision: Bool,
    sampling: Bool
  ) {
    let model = OpenAIModel(id: id)
    #expect(model.capabilities.reasoning == reasoning)
    #expect(model.capabilities.vision == vision)
    #expect(model.capabilities.sampling == sampling)
  }

  @Test("Filters models by identity and required features")
  func filtersModels() {
    let model = OpenAIModel(
      id: "gpt-custom",
      name: "Product assistant",
      owner: "team-a",
      capabilities: .init(
        toolCalling: true,
        guidedGeneration: true,
        vision: false,
        reasoning: false,
        sampling: true,
        webSearch: true
      )
    )
    #expect(
      ModelFilter(
        query: "product",
        owner: "team-a",
        requiresTools: true,
        requiresAllFeatures: [.sampling, .webSearch]
      ).matches(model)
    )
    #expect(ModelFilter(requiresVision: true).matches(model) == false)
    #expect(ModelUseCase.agent.filter.matches(model))
  }

  @Test("Builds settings metadata from the model profile")
  func buildsUIConfiguration() {
    let model = OpenAIModel(id: "gpt-5-mini")
    let ui = model.uiConfiguration
    #expect(ui.modelID == "gpt-5-mini")
    #expect(ui.showReasoningControls)
    #expect(ui.supportsTools)
    #expect(ui.supportsGuidedGeneration)
    #expect(ui.suggestedReasoning != nil)
  }
}
