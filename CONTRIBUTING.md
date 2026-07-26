# Contributing

Thanks for considering a contribution to **git-hygiene** — the local git
hooks that strip AI-attribution trailers and catch secrets before they
land in your object store. This doc covers dev setup, the testing
convention (manual recipes, no formal suite), code style, and PR
expectations.

This project is opinionated software. Read the README's "The policy" and
"What this is not" sections before opening a PR that changes behavior —
contributions that drift from the three held positions will not merge.

## Project layout

```
.
├── hooks/
│   ├── commit-msg                      # Strips AI-attribution trailers + OPSEC scan on subject
│   ├── pre-commit                      # Scans staged files: credential patterns + OPSEC content
│   ├── opsec-scan.sh                   # Sourceable library: builds $opsec_patterns from .local files
│   └── opsec-patterns.local.example    # Template for user's gitignored opsec-patterns.local
├── .github/FUNDING.yml
├── assets/                             # README hero/terminal PNGs
├── README.md
├── SECURITY.md
└── SIGNATURE.md                        # PGP signing key + signature pattern
```

No build step. The hooks are bash scripts; you edit them in place.

## Dev setup

Requires `bash`, `grep`, `awk`, `git`. [gitleaks](https://github.com/gitleaks/gitleaks)
is optional — when installed, `pre-commit` gets ~700 additional secret
detectors. [shellcheck](https://www.shellcheck.net/) is recommended for
local linting.

```bash
git clone https://github.com/JordanNewell/git-hygiene.git ~/git-hygiene

# Symlink into your global hooks path so changes to the clone go live immediately
mkdir -p ~/.githooks
ln -s ~/git-hygiene/hooks/commit-msg ~/.githooks/commit-msg
ln -s ~/git-hygiene/hooks/pre-commit  ~/.githooks/pre-commit
chmod +x ~/.githooks/*
git config --global core.hooksPath ~/.githooks
```

For per-repo development without affecting global state, set
`core.hooksPath` inside a scratch repo instead.

## Testing

There is **no formal test suite** (no BATS, no shunit2). Verification is
manual, via the recipes in `README.md` under **Verify**. Reproduce them
before sending a PR that touches hook logic.

### `commit-msg` recipe

```bash
printf 'Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>\ntest subject\n' > /tmp/msg
git commit -F /tmp/msg --allow-empty    # trailer should be stripped from the result
git log -1 --format='%B'                # must NOT contain the Co-Authored-By line
```

For OPSEC-scan coverage, set up a patterns file first (see README's
**Optional: OPSEC scan setup**), then:

```bash
printf 'S100: leak in subject\n' > /tmp/msg
git commit -F /tmp/msg --allow-empty    # should FAIL with OPSEC leak message
```

### `pre-commit` recipe

```bash
printf 'AWS_SECRET_ACCESS_KEY=abcd1234...\n' > /tmp/secret
git add /tmp/secret                     # should FAIL or warn before allowing the commit
```

### When you must extend these recipes

If your change adds a new pattern (a new AI trailer shape, a new
credential regex, an OPSEC-baseline addition), add a recipe above to the
PR description showing the before/after. "It works on my machine" is not
reviewable — paste the terminal output.

If your change adds a whole new scan layer or a new code path through
`opsec-scan.sh`, consider whether a BATS suite is finally warranted.
Open an issue first to scope it.

## Code style

- **POSIX-compliant bash** where feasible. The hooks must run on macOS
  bash 3.2 (the system default) and Linux bash 4+/5. Avoid bashisms that
  break under `sh`.
- **`shellcheck` clean.** Run `shellcheck hooks/*.sh` before sending a
  PR. SC2086 (unquoted variables) and SC2046 (word splitting) are the
  usual gotchas — quote aggressively.
- **`set -u` only, never `set -e` or `set -euo pipefail` inside hook
  entrypoints.** Scanner wrappers (`if ! gitleaks ...`) misbehave under
  `set -e` — flag errors kill the script before the exit-code branch
  runs. See commit history for the regression this caused.
- **No external runtime dependencies.** The hooks must work with only
  `bash`, `grep`, `awk`, and `git`. gitleaks is optional and probed via
  `command -v`. Adding a Python/Node dependency is a hard "no" — open an
  issue first.
- **Comments explain *why*, not *what*.** A comment that restates the
  grep below it gets deleted in review.
- **Pattern word boundaries are added automatically** by `opsec-scan.sh`
  — `ada` won't false-match inside `readable`. Don't hand-add `\b` to
  your patterns; the library does it.

## Commits

- **All commits must be PGP-signed** (Ed25519, fingerprint in
  `SIGNATURE.md`). Configure `git config commit.gpgsign true` locally.
- Subject ≤ 72 chars, imperative mood (`Add X`, `Fix Y`).
- Conventional-commit prefixes (`feat:`, `fix:`, `docs:`, `chore:`) are
  used in this repo — match them when you can.
- Reference the issue number in the body if applicable.
- **No `Co-Authored-By: Claude` or any AI-attribution trailer.**
  Ironic, given what this repo does, but also a hard policy. The
  `commit-msg` hook you're contributing to will strip it from your own
  commit — save it the work.

## Pull requests

Open a PR against `main`. CI is not currently wired (the repo has no
GitHub Actions workflow beyond FUNDING.yml), so review is manual.

Before requesting review:

- [ ] `shellcheck hooks/*.sh` is clean
- [ ] The `commit-msg` recipe above passes (trailer stripped, OPSEC
      blocks when configured)
- [ ] The `pre-commit` recipe above passes (credential blocked)
- [ ] No new runtime dependencies (gitleaks stays optional)
- [ ] README updated if user-visible behavior changed
- [ ] `opsec-patterns.local.example` updated if you added a new
      machine-level pattern category

### Release flow

There is no automated release. Hooks are consumed by symlink — once your
PR merges to `main`, anyone running `git pull` in their `~/git-hygiene`
clone picks up the change immediately. Tag releases are advisory (for
pinning) and cut by a maintainer.

## Filing issues

- 🐛 **Bugs** — include the OS, bash version (`bash --version`), the
  hook that misbehaved (`commit-msg` or `pre-commit`), the exact
  terminal output, and a minimal reproduction. **No real secrets** —
  redact before pasting.
- ✨ **New patterns** — for a new AI trailer shape, paste 3+ real
  examples from commits you've seen in the wild. For a new credential
  regex, link to the provider's token format docs.
- 📚 **Docs** — typos, dead links, missing detail.

## Security disclosures

Do **not** open a public issue for vulnerabilities in the hooks
themselves (e.g., a bypass that lets a real secret through the
`pre-commit` regex layer). See [`SECURITY.md`](SECURITY.md) for the
private reporting path.

## License

By contributing, you agree your contributions are licensed under the
[MIT license](LICENSE).