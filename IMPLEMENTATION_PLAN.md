# OpenAI for Foundation Models — Implementation Plan

## Goal

Create an OpenAI-only sibling of `OpenRouterForFoundationModels`: a Swift 6.2 package that makes OpenAI models usable through Apple Foundation Models' server-side `LanguageModel` protocol, plus a polished iOS 27 demo app and a Devpost-ready submission kit.

The reference project is the parity baseline for:

- `LanguageModel` / `LanguageModelExecutor` integration
- streamed text, reasoning, tool calls, and usage
- guided generation
- model discovery and selection
- client-side tools and dynamic profiles
- secure development and production authentication modes
- documentation, tests, demo labs, and release metadata

OpenRouter-only concepts will not be carried over:

- provider routing and provider preferences
- fallback provider/model chains
- OpenRouter plugins
- free-model pricing filters
- OpenRouter attribution headers

## Architecture

```text
App / LanguageModelSession
        |
        v
OpenAIForFoundationModels
  - OpenAILanguageModel
  - OpenAIExecutor
  - OpenAIModelCatalog
  - RequestBuilder
  - EventTranslator
  - OpenAIReasoning
        |
        v
OpenAIAPI
  - Responses API request/response types
  - semantic SSE parser
  - models endpoint
  - HTTP transport and error decoding
```

The low-level target will not import `FoundationModels`. The bridge target will translate Foundation Models transcript entries, generation guides, and tool definitions into OpenAI Responses API input items and stream events.

## OpenAI API decisions

- Use `POST https://api.openai.com/v1/responses`.
- Use semantic server-sent events and handle at minimum:
  - `response.created`
  - `response.output_text.delta`
  - `response.reasoning_summary_text.delta`
  - `response.output_item.added`
  - `response.function_call_arguments.delta`
  - `response.function_call_arguments.done`
  - `response.completed`
  - `response.failed`
  - `error`
- Use `GET https://api.openai.com/v1/models` for catalog discovery.
- Default to `store: false`; the demo owns local conversation state.
- Encode guided generation through `text.format` JSON Schema.
- Encode Foundation Models tools as strict OpenAI function tools.
- Keep API-key mode for development and HTTPS proxy mode for production.
- Never write API keys to source, `UserDefaults`, logs, fixtures, or Devpost assets.

## Concurrency and isolation

- Package tools version: Swift 6.2 or newer.
- Strict concurrency checking enabled in the demo.
- Networking types are immutable `Sendable` values.
- Streaming uses `AsyncThrowingStream` and propagates cancellation to `URLSession`.
- UI state and SwiftData-backed view coordination are `@MainActor`.
- `ModelContext` never crosses actor boundaries.
- SwiftData objects never cross actor boundaries; pass stable identifiers or value snapshots.
- No `Task.detached`, unsafe sendability, or blanket actor annotations.

## SwiftData demo model

- `ChatThread`
  - stable UUID
  - title
  - selected OpenAI model ID
  - created/updated timestamps
  - cascade relationship to messages
- `ChatMessage`
  - stable UUID
  - role
  - text
  - timestamp
  - optional response ID and token counts
  - inverse relationship to its thread
- Versioned schema and migration plan from the first release.
- In-memory containers for previews and tests.

## Milestones

### 1. Reference mapping

- Inventory public API, docs, tests, and demo flows.
- Capture parity and explicit exclusions.
- Confirm Xcode/Swift settings and Foundation Models beta surface.

### 2. Package scaffold

- Create `Package.swift`, library targets, test targets, docs, examples, CI, license, security files, and generated demo project.
- Rename public concepts consistently to OpenAI.

### 3. OpenAI transport

- Implement auth/header policy, request encoding, semantic SSE parsing, models decoding, usage/error decoding, and cancellation.
- Provide dependency-injected transport for deterministic tests.

### 4. Foundation Models bridge

- Implement request translation, capability policy, reasoning mapping, schema mapping, event translation, executor caching, and error mapping.
- Preserve Foundation Models tool-call identifiers and event order.

### 5. Demo app

- Build Chat, Models, Tools, Guided Output, Profiles/Labs, Docs, and Settings surfaces.
- Add Keychain-backed credentials and secure proxy configuration.
- Add SwiftData chat history, thread creation/deletion, and model-per-thread persistence.
- Support Dynamic Type, VoiceOver labels, Reduce Motion, keyboard dismissal, cancellation, retry, and empty/error states.

### 6. Verification and release quality

- Write new tests with Swift Testing; reserve XCTest for UI tests only.
- Run package tests, release build, demo build, and simulator smoke test.
- Verify secret redaction, malformed SSE handling, cancellation, model filtering, schema encoding, tool calls, and persistence.
- Capture screenshots only after visual inspection.

### 7. Devpost preparation (final milestone)

- Create submission title, one-line pitch, problem/solution narrative, technical architecture, feature list, challenges, accomplishments, learnings, roadmap, setup instructions, judging checklist, demo script, and media checklist.
- Include accurate build/test evidence and clearly label API-key/proxy security behavior.
- Do not submit or publish externally without explicit user approval.

## Definition of done

- Package builds with the installed Swift/Xcode toolchain.
- Unit and integration tests pass without a live key.
- Demo app builds and launches in an iOS 27 simulator.
- At least one full mocked stream covers text, usage, and completion.
- Tool-call and guided-generation translations have deterministic tests.
- SwiftData history survives app relaunch in the demo design.
- No OpenRouter implementation concepts remain in source-facing behavior.
- Devpost materials are complete and internally consistent with the verified product.

## Completion record — July 20, 2026

- OpenAI Responses and Models targets implemented.
- Foundation Models bridge implemented for transcript streaming, reasoning,
  tools, Structured Outputs, images, web search, usage, and public errors.
- SwiftUI/SwiftData demo implemented with persistent chat, model catalog,
  tools, guided output, OpenAI-only Dynamic Profiles, settings, and Keychain.
- `swift build` passed.
- 37 deterministic Swift Testing cases and one simulator UI test passed.
- `swift-format lint` passed.
- OpenAIDemo built, installed, and launched on an iPhone 17 simulator with zero
  Xcode diagnostics and no fatal/error/fault/assert runtime-log matches.
- Devpost description, judging alignment, exact form checklist, and demo script
  prepared for OpenAI Build Week.
- External publication/submission, live credential smoke, `/feedback` Session
  ID, repository URL, YouTube video, and signed TestFlight build remain explicit
  owner actions.
