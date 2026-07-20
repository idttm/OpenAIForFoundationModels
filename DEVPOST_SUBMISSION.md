# Devpost submission packet

Target: [OpenAI Build Week](https://openai.devpost.com/)

Recommended category: **Developer Tools**

Submission deadline: **Tuesday, July 21, 2026 at 5:00 PM Pacific**
(`2026-07-22T00:00:00Z`)

This file prepares the entry; it is not a submitted project. The authenticated
Devpost submission remains an explicit owner action. The official rules state:

> An Entrant may submit more than one Submission, however, each Submission must
> be unique and substantially different from each of the Entrant’s other
> Submissions, as determined by the Sponsor and Devpost in their sole
> discretion.

## Project identity

Name: **OpenAI for Foundation Models**

Devpost project:
[devpost.com/software/openai-for-foundation-models](https://devpost.com/software/openai-for-foundation-models)

OpenAI Build Week submission draft: `1107996`

Tagline:

> A Swift bridge that makes OpenAI Responses models work through Apple’s
> Foundation Models sessions, tools, streaming, and typed generation.

Category: **Developer Tools**

Built with:

- Swift 6.2
- Apple Foundation Models
- OpenAI Responses API
- GPT-5.6
- Codex
- SwiftUI
- SwiftData
- Swift Testing
- Xcode 27
- XcodeGen

## Submission description draft

Devpost’s latest announcement asks entrants to rewrite AI-assisted project copy
in their own voice. Treat the draft below as an accurate fact sheet, then edit
its phrasing before submission.

### Inspiration

Apple’s Foundation Models framework gives developers one expressive session API
for streaming, tools, and typed generation. OpenAI’s Responses API exposes a
powerful cloud model surface, but using it in an Apple app normally means
building and maintaining a parallel conversation stack.

OpenAI for Foundation Models closes that gap. It lets an Apple developer use an
OpenAI model as a Foundation Models `LanguageModel`, preserving the framework
abstractions they already use.

### What it does

The package translates a Foundation Models transcript into OpenAI Responses
input items, streams semantic server-sent events back into Apple’s generation
channel, and supports:

- streaming text and response metadata;
- strict function calling through Foundation Models `Tool` values;
- typed generation through Responses Structured Outputs;
- reasoning effort and reasoning summaries;
- image input and OpenAI-hosted web search;
- OpenAI model discovery and conservative capability profiles;
- direct development authentication and safer production relay
  authentication.

The included iOS app is more than a transport sample. It is a coherent SwiftUI
product with SwiftData conversation persistence, local transcript rehydration,
Keychain credentials, live model selection, function-tool, guided-output, and
Dynamic Profiles labs, privacy controls, and an architecture walkthrough.

### How it was built

The implementation is split into two Swift package targets. `OpenAIAPI` owns
the dependency-injectable `/v1/responses` and `/v1/models` client, semantic SSE
decoder, request types, strict tool schemas, and error envelopes.
`OpenAIForFoundationModels` owns transcript translation, reasoning and
capability policy, event translation, endpoint security, and the
`LanguageModelExecutor`.

Codex was used throughout the Build Week implementation: investigating the
reference package, checking current OpenAI and Apple API surfaces, rewriting the
provider-specific wire model, implementing the demo, diagnosing compiler
failures, constructing Swift Testing coverage, and producing the release and
submission checklists.

### Challenges

The hardest part was not sending text to an HTTP endpoint. It was preserving the
semantics of two streaming systems. Responses emits typed events for text,
reasoning, output items, function arguments, completion, usage, and failures;
Foundation Models expects generation-channel actions with stable entry IDs and
tool-call state.

Other challenges included reconstructing a Foundation Models transcript from
SwiftData without relying on OpenAI-side response storage, keeping
`Sendable`/actor boundaries strict under Swift 6, and inferring capabilities
conservatively because `GET /v1/models` does not publish a complete feature
matrix.

### Accomplishments

- A working OpenAI-only Foundation Models bridge, not a router rename.
- OpenAI Responses semantic streaming rather than Chat Completions chunks.
- Local-first conversation state with `store: false` by default.
- Exact-host protection for direct API keys and sanitized relay headers.
- A runnable iOS 27 app that builds, installs, and launches with zero Xcode
  diagnostics.
- 37 deterministic offline Swift Testing cases covering transport and bridge
  boundaries.

### What was learned

Provider adapters are safest when they translate semantic events rather than
provider-specific text chunks. Swift actor isolation also fits catalog caching
and UI state naturally, while explicit transcript persistence makes privacy
choices visible instead of hiding them inside a cloud conversation ID.

### What is next

- Validate the final demo against a live GPT-5.6 API response.
- Add a signed TestFlight build for judge-friendly installation.
- Track OS 27 and Responses event changes through the beta cycle.
- Add more explicit capability profiles as OpenAI publishes model metadata.

## Judging alignment

### Technological Implementation

- Two clean package layers with injected HTTP transport.
- Semantic Responses SSE decoding and Foundation Models event translation.
- Strict tools, Structured Outputs, reasoning, images, web search, cancellation,
  catalog caching, and public error mapping.
- 37 passing offline package tests, one passing simulator UI test, and clean
  formatting.

### Design

- Four-tab native iOS app with persistent conversations, model discovery, labs,
  and settings.
- Keychain secrets, local history, explicit response-storage toggle, and
  accessible native controls.
- Successful iPhone 17 simulator build/install/launch with no runtime faults.

### Potential Impact

The audience is Apple-platform developers adopting Foundation Models who also
need OpenAI cloud capability. The package reduces duplicated session, tool, and
typed-output infrastructure and makes the authentication/privacy boundary
explicit.

### Quality of the Idea

The novelty is treating OpenAI as a native Foundation Models `LanguageModel`,
including semantic streaming and tool state—not wrapping a chat endpoint in a
new view model.

## Required Devpost form answers

| Field | Prepared answer |
| --- | --- |
| Submitter Type | **OWNER MUST SELECT:** Individual / Team / Organization |
| Country of Residence | **OWNER MUST SELECT and verify eligibility** |
| Category | Developer Tools |
| Code repository URL | `https://github.com/idttm/OpenAIForFoundationModels` |
| Judge test link/instructions | Prefer TestFlight or signed downloadable build; otherwise provide Xcode 27 build instructions |
| `/feedback` Session ID | **REQUIRED:** capture from the primary GPT-5.6 Codex build session |
| Developer-tool instructions | Use the installation and validation section below |

## Installation and judge testing

Supported platforms:

- Package bridge: iOS, macOS, visionOS, and watchOS 27
- Demo: iOS 27
- Toolchain: Xcode 27 and Swift 6.2+

Package validation:

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
swift build
swift test
```

Demo:

```sh
cd Examples/DemoApp
xcodegen generate
open OpenAIDemo.xcodeproj
```

Select the `OpenAIDemo` scheme and an iOS 27 simulator. In Settings, use an
OpenAI development key or an HTTPS relay. No key is included in the repository.

## Required deliverables still owned by the submitter

- [ ] Confirm the project was newly created or meaningfully extended during the
      submission period and preserve dated evidence.
- [ ] Run the demo with GPT-5.6 and record the exact behavior shown in the video.
- [ ] Capture the primary GPT-5.6 Codex `/feedback` Session ID.
- [ ] Create a repository URL and ensure the checked-in history is appropriate
      for public judging.
- [ ] If private, share repository access with both required judging addresses.
- [ ] Record a public or unlisted YouTube demo under three minutes with audio
      explaining the project, Codex use, and GPT-5.6 use.
- [ ] Provide a judge-friendly install path, preferably TestFlight.
- [ ] Add screenshots and a thumbnail with no API key or private chat content.
- [ ] Select submitter type and country; personally verify the official rules
      and eligibility.
- [ ] Review this draft in the submitter’s own voice.
- [ ] Submit or update the Devpost entry before the deadline.

## Current verified state

- `swift build`: passed
- `swift test`: 37 tests passed
- `swift-format lint`: passed
- iOS simulator build: passed with zero warnings/errors
- simulator install and launch: passed
- captured runtime log scan: no fatal/error/fault/assert entries
- initial UI screenshot: visually inspected
- live GPT-5.6 API smoke: pending owner credential
- signed IPA/TestFlight: pending signing identity and distribution choice
- public repository URL: pending
- YouTube demo URL: pending
- `/feedback` Session ID: pending
