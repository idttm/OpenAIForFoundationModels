# Contributing

Thank you for helping improve OpenAI for Foundation Models. Participation in
this project is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).

## Requirements

- Xcode 27
- Swift 6.2+
- XcodeGen when changing `Examples/DemoApp/project.yml`

## Before opening a pull request

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
./scripts/release-check.sh
```

Tests must use an injected `HTTPTransport`; do not add live-network unit tests
or require contributor credentials. Keep direct API keys out of source,
fixtures, logs, and screenshots.

When a public API changes, update its tests, the demo surface that uses it, and
the relevant document under `Docs/`.

Before starting a large change, open an issue describing the intended public
API and migration impact. Small fixes can go directly to a pull request.

By submitting a contribution, you agree that it may be distributed under the
repository’s [Apache License 2.0](LICENSE).
