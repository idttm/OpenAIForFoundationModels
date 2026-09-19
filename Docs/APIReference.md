# API reference

## `OpenAILanguageModel`

The public Foundation Models adapter.

```swift
OpenAILanguageModel(
  name: OpenAIModel,
  auth: AuthMode,
  reasoning: OpenAIReasoning? = nil,
  builtInTools: Set<OpenAIBuiltInTool> = [],
  accountScope: OpenAIAccountScope? = nil,
  strictCapabilities: Bool = true,
  storeResponses: Bool = false,
  safetyIdentifier: String? = nil,
  promptCacheKey: String? = nil,
  baseURL: URL = OpenAILanguageModel.defaultBaseURL,
  timeout: TimeInterval = 120
)
```

There are convenience initializers for a model ID string and a catalog-backed
model.

## `AuthMode`

- `.apiKey(String)`: development credential; exact official HTTPS host only
- `.proxied(headers:)`: relay-managed credential; protected headers stripped

Descriptions redact credential values.

## `OpenAIModel`

Model identity and `Capabilities`:

- `toolCalling`
- `guidedGeneration`
- `vision`
- `reasoning`
- `sampling`
- `webSearch`

`uiConfiguration` provides display-ready feature state and reasoning effort
options.

## `OpenAIModelCatalog`

- `refresh(force:)`
- `models()`
- `models(for:)`
- `models(matching:)`
- `model(id:)`
- `resolve(id:refreshIfNeeded:)`
- `resolveIfPresent(id:refreshIfNeeded:)`

`ModelUseCase` presets: chat, agent, reasoning, multimodal, and structured.

## `OpenAIReasoning`

- `.automatic`
- `.effort(.max | .xhigh | .high | .medium | .low | .minimal | .none)`
- `.disabled`

A fixed value on the model takes priority over a Foundation Models request
hint. Unsupported efforts clamp to the nearest advertised effort.

## `OpenAIBuiltInTool`

`.webSearch` adds the OpenAI-hosted `web_search` tool. Foundation Models `Tool`
values remain client-side function tools.

## `OpenAIError`

Public bridge errors cover credentials, quota, unsupported capabilities,
endpoint policy, HTTP failures, empty streams, missing resources, permissions,
refusals, incomplete responses, and sanitized upstream failures. Refusal
terminal events map to `OpenAIError.refusal(message:)`; incomplete responses
preserve `incomplete_details.reason` through `OpenAIError.incomplete(reason:)`.
Rate limits, timeouts, and context-size failures map to the corresponding
`LanguageModelError`.

## Compatibility notes

Conversation state is reconstructed from the Foundation Models transcript.
Provider-authored encrypted reasoning items are not exposed losslessly there,
so encrypted reasoning replay and assistant-phase reasoning continuity are not
supported. Foundation Models per-delta token counts are approximate; exact
Responses totals are emitted as `openai.usage.*` response metadata.

Instruction entries retain their position in the conversation. Image input
applies its EXIF orientation, including mirrored orientations, to the encoded
pixels. Strict schemas reject unsupported compositions such as `allOf`
locally with `LanguageModelError.unsupportedGenerationGuide`, following the
[Structured Outputs subset](https://developers.openai.com/api/docs/guides/structured-outputs).

## `JSONValue`

Public, Sendable, Hashable, and Codable loose JSON used by tool and schema
surfaces.
