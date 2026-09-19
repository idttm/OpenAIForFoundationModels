# Contributing

Thank you for helping improve OpenAI for Foundation Models. Participation in
this project is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).

## Requirements

- Xcode 27 selected through the stable Xcode toolchain
- Swift 6.2+
- XcodeGen when changing `Examples/DemoApp/project.yml`

## Before opening a pull request

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
python3 scripts/install-publication-hooks.py
python3 -m unittest discover -s scripts/tests
./scripts/release-check.sh
```

Tests must use an injected `HTTPTransport`; do not add live-network unit tests
or require contributor credentials. Keep direct API keys out of source,
fixtures, logs, and screenshots.

When a public API changes, update its tests, the demo surface that uses it, and
the relevant document under `Docs/`.

Public repository material is limited to product source, public tests and
examples, the license, and useful contributor documentation. Never publish
private agent instructions or configuration, prompts, harness or orchestration
files, audit or log material, personal paths, or secrets. See
[Publishing](Docs/Publishing.md) for the release review.

Before starting a large change, open an issue describing the intended public
API and migration impact. Small fixes can go directly to a pull request.

By submitting a contribution, you agree that it may be distributed under the
repository’s [Apache License 2.0](LICENSE).
