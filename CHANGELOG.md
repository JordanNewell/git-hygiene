# Changelog

All notable changes to git-hygiene are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] — 2026-07-19

Initial release. Sourced from commit `109b6f8` ("Initial release:
AI-attribution strip + secret-scan git hooks"). No formal GitHub
release and no semver tags exist on this repo; the version below
reflects the public launch state as of 2026-07-19.

### Added

- **AI-attribution strip** in `commit-msg`: removes
  `Co-Authored-By: Claude` and similar AI-agent trailers before the
  commit is created.
- **Secret-scan git hooks** (`pre-commit` + `pre-push`) blocking
  leaked credentials before they reach the remote.
- **Zero dependencies** beyond `bash` / `grep` / `awk` — portable to
  any POSIX shell.

## [1.0.1] — 2026-07-22

Incremental feature additions between 2026-07-20 and 2026-07-22 (no
formal release; entries sourced from commit history on `main`).

### Added

- **Layer 3 OPSEC content scan** in `pre-commit` (`ef2d6f0`): scans
  added diff lines + filenames for OPSEC patterns (machine names,
  agent handles, codenames) that gitleaks misses.
- **Two-layer secret scan** in `pre-commit` (`f059bb2`): regex layer
  for fast local patterns + gitleaks for verified detectors.
- **Machine-level OPSEC patterns** + subject-line scan in
  `commit-msg` (`79bd502`): patterns live in
  `~/.config/opsec-patterns.local`, not per-repo.
- **Per-repo opt-out** via `git config opsec.scan=disable`
  (`a9e3a25`).
- **ZCode/GLM attribution patterns** + README accuracy pass
  (`900005e`).

### Changed

- **Case-insensitive opt-out** matching for the OPSEC scan.
- **OPSEC example baseline doc** rewritten with generic placeholders
  and accurate defaults (`8872f4d`).

[Unreleased]: https://github.com/JordanNewell/git-hygiene/commits/main
[1.0.0]: https://github.com/JordanNewell/git-hygiene/commit/109b6f8
[1.0.1]: https://github.com/JordanNewell/git-hygiene/commit/ef2d6f0