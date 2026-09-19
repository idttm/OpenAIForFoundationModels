# Testing

The package uses Swift Testing. All committed tests are deterministic and
offline; network behavior is exercised through injected `HTTPTransport`
implementations.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
./scripts/release-check.sh
```

The release check honors `DEVELOPER_DIR` or the active `xcode-select` toolchain,
requires Xcode 27 or later, builds the package in release mode, runs offline
tests, and builds the checked-in demo project without regenerating it. It uses
repo-local build output and the selected stable Xcode toolchain.

The suite covers:

- OpenAI error-envelope classification
- Responses request, input, tool, and Structured Outputs encoding
- semantic stream-event decoding and SSE framing
- flat Responses error events and rejection of truncated streams
- terminal refusal and `incomplete_details.reason` outcomes mapped to public errors
- protected request headers and account-scoping headers
- model inference, filtering, resolving, and cache reuse
- endpoint policy and credential redaction
- reasoning resolution and clamping
- Foundation Models transcript, tool, and schema mapping
- late instruction ordering and rejection of unsupported schema compositions
- decoded pixel and dimension checks for all eight image orientations
- actual OS 27 session text streaming and typed `@Generable` decoding with an offline transport
- event translation, refusal/incomplete error mapping, and cumulative response metadata

The publication guard and its offline regression tests can be run separately:

```sh
./scripts/check-repository-hygiene.sh
./scripts/check-repository-hygiene.sh --index
./scripts/check-repository-hygiene.sh --history HEAD
python3 -m unittest discover -s scripts/tests
```

The first command scans the worktree, `--index` scans staged bytes, and
`--history HEAD` scans reachable history. The history scan intentionally fails
when an existing historical exposure is found; obtain maintainer authorization
for any cleanup before changing history. The guard is heuristic, so a human
review of files, logs, and public references is still required.

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

CI should compile the portable `OpenAIAPI` target and run repository hygiene
checks. The complete bridge and demo require the selected stable Xcode 27+
toolchain, so those checks belong on a runner with that toolchain available.
