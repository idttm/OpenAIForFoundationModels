# Public release checklist

Copy this checklist for each release and leave every approval unchecked until
the current release has been reviewed. Replace `X.Y.Z` and other placeholders.

## Scope and identity

- [ ] Release version, date, owner, and exact target remote are recorded.
- [ ] The public set contains only product source, public tests and examples,
      the license, and useful contributor documentation.
- [ ] Private agent instructions or configuration, prompts, harness or
      orchestration files, audit or log material, personal paths, and secrets
      are excluded.
- [ ] License, trademark, security-reporting, and support references are
      current and point to public locations.
- [ ] Commit authorship and repository ownership are appropriate for release.

## Guard and validation

- [ ] Publication guards are installed while preserving existing hooks:
      `python3 scripts/install-publication-hooks.py`.
- [ ] Worktree scan passes:
      `./scripts/check-repository-hygiene.sh`.
- [ ] Index scan passes:
      `./scripts/check-repository-hygiene.sh --index`.
- [ ] Full reachable-history scan passes:
      `./scripts/check-repository-hygiene.sh --history HEAD`.
- [ ] Publication guard tests pass:
      `python3 -m unittest discover -s scripts/tests`.
- [ ] Selected stable Xcode 27+ package, offline test, and demo checks pass.
- [ ] Direct-key and relay smoke checks, if claimed for this release, are
      reviewed without recording credentials or sensitive prompts.

The `--history HEAD` guard intentionally blocks existing historical exposures
until a maintainer authorizes cleanup. A history rewrite cannot erase clones,
caches, forks, or previously published artifacts. The guard is heuristic and
does not replace human review.

## Release notes and assets

- [ ] `CHANGELOG.md` and release notes are finalized for `X.Y.Z`.
- [ ] Screenshots, archives, sample projects, and other release assets contain
      no private material or credentials.
- [ ] CI logs and generated artifacts have been reviewed for private values,
      personal paths, and accidental configuration.
- [ ] Every README, documentation, package, security, and support reference
      resolves to the intended public location.
- [ ] All public file changes, tests, examples, and license text are reviewed.

## Maintainer authorization

- [ ] Maintainer approves the exact public file list and release assets.
- [ ] Maintainer approves the exact tag, remote, and mutation commands.
- [ ] Release publication is recorded with the resulting public references.
