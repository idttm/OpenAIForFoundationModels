# Catalog and capabilities

`OpenAIModelCatalog` loads `GET /v1/models`, caches the result for one hour by
default, and coalesces refreshes through actor isolation.

```swift
let catalog = try OpenAIModelCatalog(auth: .apiKey(apiKey))
let models = try await catalog.refresh()

let agents = await catalog.models(for: .agent)
let reasoning = await catalog.models(for: .reasoning)
let selected = try await catalog.resolve(id: "gpt-5-mini")
```

## Why capabilities are inferred

The Models endpoint returns model identity, creation time, and ownership. It
does not expose a complete matrix for Responses, tools, images, reasoning, or
Structured Outputs. The bridge therefore uses conservative family-level
inference.

For an internal deployment with known behavior, pass an explicit profile:

```swift
let deployment = OpenAIModel(
  id: "my-deployment",
  capabilities: .init(
    toolCalling: true,
    guidedGeneration: true,
    vision: false,
    reasoning: false,
    sampling: true,
    webSearch: true
  )
)
```

`strictCapabilities` defaults to `true`. If a request asks for a feature the
profile does not advertise, the bridge fails locally instead of sending a
guess to the API.

`resolveIfPresent` is useful for user-entered IDs. It returns a conservative
model value when the ID is absent from a successfully loaded catalog; transport
and authentication failures still throw.
