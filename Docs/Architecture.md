# Architecture

```text
LanguageModelSession
  → OpenAILanguageModel
  → OpenAIExecutor
  → RequestBuilder
  → OpenAIClient
  → POST /v1/responses
  → semantic SSE events
  → EventTranslator
  → Foundation Models generation channel
```

## Package boundary

`OpenAIAPI` has no Foundation Models dependency. It owns HTTP configuration,
request encoding, response decoding, Models DTOs, semantic stream events, and
SSE framing.

`OpenAIForFoundationModels` owns Apple-framework integration:

- `RequestBuilder` maps a `Transcript` to Responses input items.
- `ReasoningPolicy` resolves fixed and per-request effort.
- Foundation Models tool schemas become strict Responses function tools.
- `GenerationSchema` becomes Responses `text.format`.
- Attachments become PNG data URLs when vision is supported.
- `EventTranslator` emits metadata, text, reasoning, tool arguments, and usage.
- `ErrorMapper` ensures package-internal wire errors never escape publicly.

## Conversation state

The bridge sends the Foundation Models transcript on each request and defaults
to `store: false`. It does not depend on `previous_response_id`, which keeps
conversation state under the app’s control and allows the SwiftData demo to
rehydrate a session locally.

Rendered reasoning entries are not replayed. Responses reasoning items can
contain provider-authored opaque data that the Foundation Models transcript
does not expose losslessly.

## Concurrency

- `OpenAIModelCatalog` is an actor and caches one in-flight refresh.
- Streaming uses `AsyncThrowingStream`.
- Terminating a consumer cancels its producer task.
- The URLSession byte bridge checks cancellation between bytes and events.
- The demo’s controllers are `@MainActor`; networking remains asynchronous.

## Security boundary

`EndpointPolicy` restricts direct keys to the exact official host. Relay URLs
must use HTTPS, except loopback HTTP for local development. Protected headers
are always re-applied after caller extras are sanitized.
