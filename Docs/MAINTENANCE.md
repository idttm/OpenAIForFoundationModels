# Maintenance

When Xcode or the OpenAI Responses API changes:

1. Verify the official Responses, streaming, function-calling, Structured
   Outputs, models, and conversation-state documentation.
2. Update wire DTOs and semantic event decoding in `OpenAIAPI`.
3. Update transcript and event mapping in `OpenAIForFoundationModels`.
4. Add or adjust offline fixtures in Swift Testing.
5. Run `swift build`, `swift test`, regenerate the demo project, and build/run
   the demo on the latest simulator.
6. Update README, API reference, changelog, and Devpost materials together.

Do not infer OpenAI capabilities from marketing names unless the Models endpoint
or a maintained family rule supports the inference. Prefer a conservative
profile and an explicit app override.
