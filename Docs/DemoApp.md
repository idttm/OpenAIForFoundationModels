# OpenAIDemo

The iOS 27 demo is a working SwiftUI and SwiftData client for the local package.

## Tabs

- Chat: persistent threads, transcript rehydration, streaming, cancel, delete
- Models: live `GET /v1/models` catalog, search, feature profile, selection
- Labs: Foundation Models function tools, typed generation, and Dynamic Profiles
- Settings: Keychain API key or relay token, model, reasoning, privacy, scope

The Labs list also contains an architecture walkthrough that explains which
layer owns each operation.

The Profiles lab keeps one `LanguageModelSession` transcript while switching
between fast and deep OpenAI profiles. Each profile can change model,
instructions, reasoning level, and tool policy without introducing a
non-OpenAI provider.

## Persistence

`ChatThread` and `ChatMessage` are SwiftData models in `ChatSchemaV1`.
`ChatMigrationPlan` establishes the versioned schema boundary. Deleting a
thread cascades to its messages.

Before sending a new prompt, `TranscriptBuilder` creates a Foundation Models
`Transcript` from stored user and assistant messages. That lets a conversation
survive app relaunch without requiring OpenAI-side response storage.

## Credentials

Secrets use `KeychainStore`. Non-secret settings use `UserDefaults`. The app
does not ship a bundled key.

## Generate and run

```sh
cd Examples/DemoApp
xcodegen generate
open OpenAIDemo.xcodeproj
```

The checked-in bundle identifier is
`org.example.OpenAIDemo`. For local signing, set `DEVELOPMENT_TEAM` in the
ignored `LocalSigning.xcconfig` beside `project.yml`; `Signing.xcconfig`
includes it when present. Keep personal signing settings out of the project
file and change the bundle identifier before device distribution.
