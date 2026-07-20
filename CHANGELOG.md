# Changelog

## 0.1.0 — Unreleased

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
- 37 deterministic offline Swift Testing cases and one simulator UI test.

### Fixed

- Optional Foundation Models tool parameters now encode as OpenAI strict
  required-and-nullable schema properties.
- Schema-validation errors containing “context” are no longer mislabeled as
  transcript context-window failures.
- Failed or cancelled chat requests no longer persist empty placeholder
  assistant messages.
- Keyboard dismissal uses native Return, scrolling, and presentation behavior
  without a custom oversized keyboard accessory.

### Security

- Direct keys are restricted to `https://api.openai.com`.
- Relay headers cannot override authorization, content, account, or
  hop-by-hop headers.
- Credential-shaped text is redacted from public errors and debug descriptions.
- Responses use `store: false` by default.
