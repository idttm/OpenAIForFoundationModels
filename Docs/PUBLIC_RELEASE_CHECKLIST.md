# Public release checklist

## Source and identity

- [x] Public repository owner and URL chosen
- [x] Package installation snippets updated with the real URL
- [ ] License and trademark wording reviewed
- [ ] Commit author identity is appropriate for publication
- [x] No private design notes or local absolute paths

## Security

- [x] No API keys, tokens, `.env`, Keychain exports, or signing credentials
- [x] Repository hygiene and OpenAI-key patterns reviewed
- [x] Direct-key mode is described as development-only
- [x] Security advisory/reporting channel configured
- [x] Demo screenshots contain no credentials or private conversation data

## Validation

- [x] `swift build`
- [x] `swift test` — 37 package tests
- [x] `xcodegen generate`
- [x] Demo builds, installs, launches, and shows all four tabs
- [ ] Direct-key development flow smoke-tested manually
- [ ] Relay flow smoke-tested before claiming production readiness

## Release assets

- [x] README and local documentation links work
- [ ] `CHANGELOG.md` finalized
- [ ] Version/tag selected
- [ ] Devpost copy, screenshots, demo video, and repository URL reviewed
- [x] Submission owner explicitly approves this public repository publish
