# Publishing

Use this procedure as a fresh per-release review. Replace `X.Y.Z` and other
placeholders for the release under review; do not carry approvals forward from
an earlier release.

The public set may contain product source, public tests and examples, the
license, and useful contributor documentation. It must never contain private
agent instructions or configuration, prompts, harness or orchestration files,
audit or log material, personal paths, or secrets.

## Prepare

1. [ ] Copy [PUBLIC_RELEASE_CHECKLIST.md](PUBLIC_RELEASE_CHECKLIST.md) and
   complete every item for `X.Y.Z`.
2. [ ] Confirm the package URL, owner, release notes, and public asset list.
3. [ ] Install the local publication guards, preserving existing hooks:

   ```sh
   python3 scripts/install-publication-hooks.py
   ```

4. [ ] Run the selected stable Xcode 27+ toolchain checks in
   [Testing.md](Testing.md).
5. [ ] Run the publication guard at each required scope:

   ```sh
   ./scripts/check-repository-hygiene.sh
   ./scripts/check-repository-hygiene.sh --index
   ./scripts/check-repository-hygiene.sh --history HEAD
   python3 -m unittest discover -s scripts/tests
   ```

The default command scans the worktree, `--index` scans staged bytes, and
`--history HEAD` scans reachable history. The full-history guard intentionally
blocks an existing historical exposure until a maintainer authorizes cleanup.
History rewrites cannot erase clones, caches, forks, or previously published
artifacts. The guard is heuristic; a maintainer must review the actual files,
release notes, assets, CI logs, and every public reference.

## Release review

- [ ] `CHANGELOG.md` and release notes describe only the reviewed `X.Y.Z`.
- [ ] Screenshots, archives, sample projects, and other release assets contain
      no private material or credentials.
- [ ] CI logs and generated artifacts have been reviewed for private values and
      paths.
- [ ] All README, documentation, package, security, and support references
      point to the intended public locations.
- [ ] The exact public file list and remote target have maintainer approval.

## Publish

Do not mutate a remote, create a release, or rewrite history until the
maintainer has authorized the exact commands, target, tag, and file set. After
that approval, publish only the approved `X.Y.Z` tag and release assets, then
record the resulting public references in the release record.

Consumers can use the approved package URL and version:

```swift
.package(
  url: "<PUBLIC_REPOSITORY_URL>",
  from: "X.Y.Z"
)
```
