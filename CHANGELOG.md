# Changelog

## 0.1.0 — 2026-09-19

### Added

- OpenAI-only Foundation Models bridge backed by `POST /v1/responses`.
- Semantic Responses SSE parsing, including text, reasoning, function-call,
  completion, usage, and error events.
- Foundation Models transcript, tool, vision, reasoning, and guided-generation
  translation.
- OpenAI model catalog with actor-isolated caching and conservative capability
  inference.
- Direct development authentication and production relay authentication.
- SwiftUI + SwiftData iOS demo with persistent chat and Keychain credentials.
- Searchable, deduplicated model selection for Settings and conversations.
- Command-line streaming and catalog example.
- Deterministic offline Swift Testing coverage and a simulator UI test.

### Fixed

- Updated transcript segment mapping for the released OS 27 SDK, which removed
  the beta-only `Transcript.Segment.custom` case.
- Truncated Responses streams now fail instead of accepting partial output as
  a complete response; flat SSE error events preserve the upstream error.
- Refusal terminal events and refusal content now surface as explicit errors
  instead of blank successful output; incomplete responses preserve their
  `incomplete_details.reason`.
- Stream metadata updates retain prior model and response identifiers while
  adding cumulative usage metadata.
- Image attachments apply all eight EXIF orientations to their encoded pixels.
- Instruction changes retain their position in conversation history.
- Unsupported strict schema compositions fail locally before a network request.
- Release verification honors the selected Xcode 27 toolchain and preserves
  local demo-project settings instead of regenerating.

- Optional Foundation Models tool parameters now encode as OpenAI strict
  required-and-nullable schema properties.
- Schema-validation errors containing “context” are no longer mislabeled as
  transcript context-window failures.
- Failed or cancelled chat requests no longer persist empty placeholder
  assistant messages.
- Keyboard dismissal uses native Return, scrolling, and presentation behavior
  without a custom oversized keyboard accessory.
- The demo creates its SwiftData Application Support directory before opening
  `default.store`, avoiding first-launch Core Data recovery errors.
- OpenAI token usage is emitted as response metadata instead of linking the
  beta-only Foundation Models `updateUsage` symbol missing from some iOS 27
  runtimes.

### Security

- Direct keys are restricted to `https://api.openai.com`.
- Relay headers cannot override authorization, content, account, or
  hop-by-hop headers.
- Credential-shaped text is redacted from public errors and debug descriptions.
- Responses use `store: false` by default.
- Publication guards check staged content and complete outgoing history, with
  local hook installation, CI checks, and synthetic regression fixtures.
