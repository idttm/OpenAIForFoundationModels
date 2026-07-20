# Testing

The package uses Swift Testing. All committed tests are deterministic and
offline; network behavior is exercised through injected `HTTPTransport`
implementations.

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
./scripts/release-check.sh
```

The suite covers:

- OpenAI error-envelope classification
- Responses request, input, tool, and Structured Outputs encoding
- semantic stream-event decoding and SSE framing
- protected request headers and account-scoping headers
- model inference, filtering, resolving, and cache reuse
- endpoint policy and credential redaction
- reasoning resolution and clamping
- Foundation Models transcript, tool, and schema mapping
- event translation and public error mapping

Build the demo separately:

```sh
xcodebuild \
  -project Examples/DemoApp/OpenAIDemo.xcodeproj \
  -scheme OpenAIDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

Live API checks belong in a manual smoke workflow, not the unit suite:

```sh
OPENAI_API_KEY=… swift run OpenAIExample \
  --model gpt-5-mini \
  --prompt "Reply with OK."
```

Never record a live key, complete request headers, or sensitive prompt content
in test output.

The hosted CI job compiles the portable `OpenAIAPI` target and runs repository
hygiene checks. The complete bridge and demo require Xcode 27, so the full CI
job is manual and targets a self-hosted Xcode 27 runner until that toolchain is
available on a hosted runner.
