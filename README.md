# OpenAI for Foundation Models

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-Apple%20OS%2027-lightgrey.svg)](Package.swift)
[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](Package.swift)

Use OpenAI models through Apple’s Foundation Models framework. The package
adapts OpenAI’s Responses API to `LanguageModel`, so apps can use
`LanguageModelSession` for streaming text, typed generation, client-side tools,
reasoning, image input, and OpenAI-hosted web search.

This is an OpenAI-only implementation: requests go to `POST /v1/responses`,
model discovery uses `GET /v1/models`, and no router, third-party provider, or
fallback-provider configuration is present.

> Beta: the bridge targets the server-side language-model APIs in Apple OS 27
> and requires Xcode 27. Those APIs can change during the beta cycle.

This is an independent community project. It is not affiliated with, endorsed
by, or sponsored by OpenAI or Apple. OpenAI, Apple, and their product names are
trademarks of their respective owners.

## What is included

- `OpenAIAPI`: dependency-injectable Responses API and Models client
- `OpenAIForFoundationModels`: `LanguageModel` and `LanguageModelExecutor`
- Semantic SSE parsing for Responses events
- Transcript mapping for developer, user, assistant, and function-call items
- Strict function tools and Structured Outputs
- Reasoning effort, image input, web search, usage, and response metadata
- Actor-isolated model catalog with conservative capability inference
- API-key endpoint allow-listing and sanitized relay headers
- SwiftUI + SwiftData iOS demo with persistent local conversations
- 37 offline Swift Testing cases; no test requires an API key

## Requirements

- Swift 6.2+
- Xcode 27
- iOS, macOS, visionOS, or watchOS 27 for the bridge
- An OpenAI API key for development, or an authenticated relay for a shipping app

## Add the package

While developing locally:

```swift
dependencies: [
  .package(path: "../OpenAIForFoundationModels")
]
```

For a published release:

```swift
dependencies: [
  .package(
    url: "https://github.com/idttm/OpenAIForFoundationModels.git",
    from: "0.1.0"
  )
]
```

Source and releases are published at
[github.com/idttm/OpenAIForFoundationModels](https://github.com/idttm/OpenAIForFoundationModels).

## Quick start

```swift
import FoundationModels
import OpenAIForFoundationModels

let model = OpenAILanguageModel(
  name: "gpt-5-mini",
  auth: .apiKey(apiKey),
  reasoning: .effort(.medium)
)

let session = LanguageModelSession(model: model)
let response = try await session.respond(
  to: "Plan a focused weekend in Kyoto."
)
print(response.content)
```

Streaming uses the Foundation Models API:

```swift
for try await partial in session.streamResponse(to: "Explain SSE briefly.") {
  print(partial.content)
}
```

## Tools, web search, and typed output

Client-side tools remain ordinary Foundation Models `Tool` values:

```swift
let model = OpenAILanguageModel(
  name: "gpt-5-mini",
  auth: .apiKey(apiKey),
  builtInTools: [.webSearch]
)
let session = LanguageModelSession(
  model: model,
  tools: [myClockTool],
  instructions: "Use tools only when they improve the answer."
)
```

Guided generation is translated to Responses `text.format` with a strict JSON
schema:

```swift
@Generable
struct Itinerary {
  var destination: String
  var highlights: [String]
}

let result = try await session.respond(
  to: "Create a three-day itinerary.",
  generating: Itinerary.self
)
```

## Model catalog

OpenAI’s Models endpoint provides identity and ownership, not a full
capability matrix. The catalog therefore applies conservative family-level
inference and lets callers provide an explicit `OpenAIModel.Capabilities` for a
custom deployment.

```swift
let catalog = try OpenAIModelCatalog(auth: .apiKey(apiKey))
let models = try await catalog.refresh()
let reasoningModels = await catalog.models(for: .reasoning)
let selected = try await catalog.resolve(id: "gpt-5-mini")

let model = OpenAILanguageModel(
  catalogModel: selected,
  auth: .apiKey(apiKey)
)
```

`strictCapabilities` defaults to `true`, so unsupported tools, vision, or
guided generation fail before the request is sent.

## Authentication and privacy

Direct API-key mode is for development. It only permits
`https://api.openai.com` and protects authorization and account-scoping
headers from per-request overrides.

```swift
.apiKey(apiKey)
```

For a distributed app, use a relay that adds the OpenAI credential server-side:

```swift
let model = OpenAILanguageModel(
  name: "gpt-5-mini",
  auth: .proxied(headers: ["X-App-Token": relayToken]),
  baseURL: URL(string: "https://api.example.com/openai/v1")!
)
```

Responses are sent with `store: false` by default. The demo stores conversation
history locally with SwiftData and stores credentials in Keychain.

See [Docs/SECURITY.md](Docs/SECURITY.md) before shipping.

## Run the examples

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
export OPENAI_API_KEY=sk-proj-…

swift run OpenAIExample --model gpt-5-mini --prompt "Say hello."
swift run OpenAIExample --list --use-case reasoning
```

The iOS demo project is generated with XcodeGen and checks in the generated
project:

```sh
cd Examples/DemoApp
xcodegen generate
open OpenAIDemo.xcodeproj
```

Save a development key in Settings or configure an HTTPS relay. The app includes
persistent chat, live model catalog, function-tool, guided-generation, and
Dynamic Profiles labs, architecture notes, and privacy controls.

## Validate

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
./scripts/release-check.sh
```

The release check scans repository hygiene, lints Swift sources, runs all
offline package tests, regenerates the demo project, and builds the demo for an
iOS Simulator without code signing.

## Built with Codex

Codex was used during OpenAI Build Week to investigate the reference
architecture, implement the OpenAI Responses transport and Foundation Models
bridge, build the SwiftUI/SwiftData demo, write offline tests, diagnose
compiler/runtime issues, and prepare the documentation.

## Documentation

- [Getting started](Docs/GettingStarted.md)
- [Architecture](Docs/Architecture.md)
- [API reference](Docs/APIReference.md)
- [Catalog and capabilities](Docs/CatalogAndCapabilities.md)
- [Demo app](Docs/DemoApp.md)
- [Security](Docs/SECURITY.md)
- [Testing](Docs/Testing.md)
- [Support](SUPPORT.md)
- [Contributing](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)

OpenAI API behavior is based on the official
[Responses](https://developers.openai.com/api/reference/resources/responses/methods/create),
[streaming](https://developers.openai.com/api/docs/guides/streaming-responses),
[function calling](https://developers.openai.com/api/docs/guides/function-calling),
and [Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
documentation.
