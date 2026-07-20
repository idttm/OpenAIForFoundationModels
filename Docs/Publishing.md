# Publishing

The project is ready for a repository and an initial `0.1.0` tag, but no remote
or package URL is assumed.

## Before publishing

1. Complete [PUBLIC_RELEASE_CHECKLIST.md](PUBLIC_RELEASE_CHECKLIST.md).
2. Choose the public repository owner and URL.
3. Replace local package-install examples with that URL.
4. Update security-reporting links after the repository exists.
5. Run the package and demo validations in [Testing.md](Testing.md).
6. Review `CHANGELOG.md` and remove the “Unreleased” marker.
7. Review the exact files that will be public:

```sh
git status --short --ignored
./scripts/check-repository-hygiene.sh
```

## Release

```sh
git tag -a 0.1.0 -m "OpenAI for Foundation Models 0.1.0"
git push origin main
git push origin 0.1.0
```

Create release notes from `CHANGELOG.md`. A consumer can then use:

```swift
.package(
  url: "https://github.com/idttm/OpenAIForFoundationModels.git",
  from: "0.1.0"
)
```

Do not publish or submit to a hackathon from automation without the maintainer’s
explicit approval.
