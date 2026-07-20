# OpenAI Build Week demo script

Target length: **2:30–2:45**. The uploaded YouTube video must remain under three
minutes and include audio explaining the project, Codex, and GPT-5.6.

## 0:00–0:20 — Problem

“Apple’s Foundation Models framework has a great session API for streaming,
tools, and typed generation. But when an app also needs an OpenAI cloud model,
developers usually build a second conversation stack. OpenAI for Foundation
Models removes that duplication.”

Show:

- package README title and one-line purpose;
- the two source targets in Xcode.

## 0:20–0:50 — Native model bridge

“This package makes an OpenAI Responses model conform to Foundation Models’
`LanguageModel`. The app still uses `LanguageModelSession`, including ordinary
streaming, tools, and generated types.”

Show:

- `OpenAILanguageModel`;
- the short README quick-start;
- `POST /v1/responses` in `OpenAIClient`.

## 0:50–1:25 — Working iOS app

“The demo is a complete SwiftUI and SwiftData app. Conversations persist
locally, credentials stay in Keychain, and OpenAI-side response storage is off
by default.”

Show:

- Chat tab and new conversation;
- Models tab with GPT-5.6 selected;
- a short GPT-5.6 streamed answer;
- relaunching or reopening the persisted thread.

Do not show the API key.

## 1:25–1:55 — Tools and typed output

“Foundation Models client tools become strict Responses function tools, and
`@Generable` schemas become Responses Structured Outputs.”

Show:

- Tools lab producing a clock/calculator result;
- Guided lab producing a typed trip plan;
- the relevant request builder code briefly.

## 1:55–2:20 — Engineering depth

“The bridge translates semantic Responses events—text, reasoning, tool
arguments, completion, usage, and failures—into Foundation Models generation
actions. Direct keys are restricted to the exact OpenAI host, and production
apps can use a sanitized relay.”

Show:

- `ResponseStreamEvent`;
- `EndpointPolicy`;
- terminal result for 37 passing package tests.

## 2:20–2:45 — Codex and GPT-5.6

“Codex helped investigate the reference architecture, implement the OpenAI-only
transport and bridge, diagnose the Swift 6 and Xcode 27 boundaries, write the
offline tests, and prepare the release. GPT-5.6 powers the demonstrated OpenAI
session and was used in the documented Codex build session.”

Show:

- the primary Codex `/feedback` Session ID;
- the running GPT-5.6 model label;
- final app screen and project name.

Only make the final sentence if both uses are verified before recording.

## Recording checklist

- [ ] 1920×1080 or a readable portrait-device layout
- [ ] public or unlisted YouTube visibility checked in a private browser
- [ ] under 3:00
- [ ] audible narration
- [ ] working project visibly demonstrated
- [ ] Codex contribution explained
- [ ] GPT-5.6 use explained and shown
- [ ] no third-party music, private messages, keys, or signing identifiers
