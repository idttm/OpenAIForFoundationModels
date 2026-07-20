# OpenAIDemo

An iOS 27 SwiftUI + SwiftData reference app for
`OpenAIForFoundationModels`.

## Run

```sh
cd Examples/DemoApp
xcodegen generate
open OpenAIDemo.xcodeproj
```

The generated project links the local package at `../..`. Select your own
development team before installing on a physical device.

## First launch

1. Open Settings.
2. Save a development OpenAI API key in Keychain, or select Relay and enter an
   HTTPS relay URL/token.
3. Open Models and refresh the live catalog.
4. Select a model and create a conversation in Chat.
5. Try the client-tool, guided-generation, and Dynamic Profiles labs.

## App surfaces

| Tab | Purpose |
| --- | --- |
| Chat | SwiftData threads, transcript rehydration, streaming, cancellation |
| Models | Live catalog, search, capability profile, model selection |
| Labs | Function tool, typed output, Dynamic Profiles, and architecture demonstrations |
| Settings | Authentication, reasoning, privacy, and optional account scope |

Secrets use Keychain. Conversations stay local in SwiftData. OpenAI response
storage is off by default.

See [Docs/DemoApp.md](../../Docs/DemoApp.md) and
[Docs/SECURITY.md](../../Docs/SECURITY.md).
