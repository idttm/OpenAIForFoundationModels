import FoundationModels
import OpenAIForFoundationModels

struct OpenAIProfileSet: LanguageModelSession.DynamicProfile {
  let fast: OpenAILanguageModel
  let deep: OpenAILanguageModel
  let tools: [any Tool]

  @SessionProperty(\.openAIProfileMode) private var mode

  var body: some LanguageModelSession.DynamicProfile {
    if mode == .deep {
      LanguageModelSession.Profile {
        Instructions(
          """
          You are a careful OpenAI reasoning assistant. Check assumptions and \
          prefer accuracy over speed.
          """
        )
        tools
      }
      .model(deep)
      .reasoningLevel(.deep)
      .toolCallingMode(tools.isEmpty ? .disallowed : .allowed)
    } else {
      LanguageModelSession.Profile {
        Instructions(
          """
          You are a fast OpenAI assistant. Give a concise, direct answer.
          """
        )
        tools
      }
      .model(fast)
      .toolCallingMode(tools.isEmpty ? .disallowed : .allowed)
    }
  }
}
