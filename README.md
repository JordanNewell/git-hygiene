# git-hygiene

> Tools don't get co-author credit.

A small set of git hooks that enforce a hygiene policy: keep AI-tool attribution out of commit messages, keep secrets out of staged files. No dependencies beyond `bash`, `grep`, `awk`, and `git` itself.

## The policy

Three positions, held firmly:

1. **AI tools are tools.** Claude, Copilot, Cursor, Gemini, ChatGPT — they're how the work gets done, not who did the work. The author is the human; the tool is the tool. You don't credit DeWalt on the shed you built with their drill.
2. **Secrets stay out of git.** API keys, tokens, passwords — pre-commit catches the high-precision patterns before they land in your object store.
3. **Local enforcement, no SaaS dependency.** The hooks run on your machine against your staged files. No telemetry, no cloud calls, no third-party scans.

## What's included

```
hooks/
├── commit-msg                      # Strips AI-attribution trailers + OPSEC scan on subject
├── pre-commit                      # Scans staged files for credential-shaped patterns
├── opsec-scan.sh                   # Sourceable library: builds $opsec_patterns from .local files
└── opsec-patterns.local.example    # Template for user's gitignored opsec-patterns.local
```

### `commit-msg`

Strips lines matching any of these patterns (case-insensitive):

- `Co-Authored-By: <anything>Claude/Copilot/Cursor/Gemini/ChatGPT/GitHub Copilot/anthropic`
- `Co-Authored-By: <AI` or `Co-Authored-By: ...AI`
- `Generated with Claude/Copilot/Cursor/Gemini` (catches the `🤖 Generated with Claude Code` standard trailer too — emoji not required in the pattern, survives grep locale issues)
- `Generated-with: Claude`
- `Written by Claude` / `Created by Claude`
- `AI-assisted:`
- `noreply@anthropic.com` / `noreply@github.com ... copilot`

Legitimate human co-authors (`Co-Authored-By: Jane Doe <jane@example.com>`) are preserved. Body content referencing Claude Code as a tool ("the Claude Code agent was mangling whitespace") is preserved — only trailer-shaped patterns are stripped.

### `pre-commit`

Scans staged files for the common high-precision credential patterns:

- AWS access keys (`AKIA...`) and secret keys
- OpenAI (`sk-or-...`), GitHub (`ghp_/gho_/ghu_/ghs_/ghr_/github_pat_...`), Slack (`xoxb-/xoxp-`) tokens
- Bearer tokens, generic API keys / passwords / secrets matching `key="..."` assignments
- Skips `node_modules/`, `*.min.js`, `*.min.css`, `.obsidian/plugins/*/main.js`

Optional TruffleHog integration when available. Falls back to grep-only otherwise.

### `opsec-scan.sh` (optional — for operators with internal infrastructure)

Sourceable library that builds a `$opsec_patterns` regex from up to three layers:

1. **Hardcoded baseline** (tracked) — session IDs (`Sxxx` convention) + Tailscale CGNAT IPs (`100.x.x.x`). Safe for everyone.
2. **Machine-level** — `$HOME/.config/opsec-patterns.local` (gitignored). Your real hostnames, tailnet name, codenames, agent handles. Defined once per machine, applies to every repo you commit to.
3. **Repo-local** — `./.opsec-patterns.local` (gitignored). Optional extras for project-specific patterns.

The `.local` files are gitignored by convention — they contain real infrastructure identifiers that are themselves OPSEC-sensitive. See [`hooks/opsec-patterns.local.example`](hooks/opsec-patterns.local.example) for the contract.

`commit-msg` sources this library and scans the commit subject (first line) for matches. Bodies are not scanned — legitimate prose may mention collaborators by name. If no `.local` files are present, only the hardcoded baseline runs (safe default for OSS contributors).

Pattern word boundaries are added automatically — `ada` won't false-match inside `readable` or `metadata`.

## Install

### Per-user (recommended — applies to every repo you own)

```bash
git clone https://github.com/JordanNewell/git-hygiene.git ~/git-hygiene

# Symlink into your global hooks path
mkdir -p ~/.githooks
ln -s ~/git-hygiene/hooks/commit-msg ~/.githooks/commit-msg
ln -s ~/git-hygiene/hooks/pre-commit  ~/.githooks/pre-commit
chmod +x ~/.githooks/*

# Tell git to use that hooks path globally
git config --global core.hooksPath ~/.githooks
```

### Per-repo (if you want it scoped)

```bash
cd /path/to/repo
git config core.hooksPath /path/to/git-hygiene/hooks
```

### Verify

```bash
# Test commit-msg
echo "Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>" > /tmp/msg
echo "test subject" >> /tmp/msg
git commit -F /tmp/msg --allow-empty  # trailer should be stripped from the result
git log -1 --format='%B'

# Test pre-commit
echo "AWS_SECRET_ACCESS_KEY=abcd1234..." > /tmp/secret
git add /tmp/secret  # should fail or warn
```

### Optional: OPSEC scan setup

If you commit to public repos from a machine that also hosts internal infrastructure (homeserver, agent fleet, internal codenames), enable the OPSEC scan:

```bash
# 1. Create your machine-level patterns file
mkdir -p ~/.config
cp ~/git-hygiene/hooks/opsec-patterns.local.example ~/.config/opsec-patterns.local

# 2. Edit ~/.config/opsec-patterns.local — replace examples with your real values
#    (hostnames, tailnet name, agent handles, codenames, internal service names)

# 3. Test — commit-msg will now block subjects containing your patterns
echo "S100: test session id" > /tmp/msg
git commit -F /tmp/msg --allow-empty  # should FAIL with OPSEC leak message
```

Repos that want project-specific patterns on top of the machine-level set can add a `./.opsec-patterns.local` file (don't forget to gitignore it).

## Layered defense

The hook is one of three layers. Belt, suspenders, and a third belt.

1. **Editor / agent setting** — Claude Code's `~/.claude/settings.json` has `includeCoAuthoredBy: false`. Stops the trailer from being emitted in the first place. Copilot, Cursor, etc. have their own equivalents.
2. **This hook** — `commit-msg` catches what slips through. Doesn't care which tool emitted the trailer.
3. **CLAUDE.md / AGENTS.md instruction** — behavioral rule for AI agents operating in the repo.

Each layer fails open independently. The three together are robust.

## Why this matters

**Copyright / IP.** Mixing AI co-authorship into commit metadata muddies who owns the code. Some jurisdictions are starting to litigate AI-assisted work; clean attribution history is a defense.

**Hiring signals.** Future employers, acquirers, contributors read your commit history. A repo where every commit says `Co-Authored-By: Claude` reads as performative — "look, I use AI!" — which is the opposite of how senior operators signal taste.

**Audit trails.** For regulated industries (defense, finance, health), AI-assisted code is a real disclosure question. Some orgs prohibit it entirely. A clean commit history that doesn't carry AI attribution sidesteps the question; a dirty one raises it.

## What this is not

- Not a watermark / steganography tool
- Not a supply-chain attestation framework (look at SLSA / Sigstore for that)
- Not a replacement for `pre-commit` framework, Husky, GitGuardian, or TruffleHog as a service
- Not a policy engine for org-level enforcement (use GitHub push rules for that)

It's a small, focused set of hooks for individual operators who want clean local commit hygiene without depending on a SaaS.

## License

MIT — see [LICENSE](LICENSE).

## Signature

This repo follows the [Jordan Newell code-signature pattern](https://jordannewell.com/signature/). PGP fingerprint: `67567DC5E7C5353F85F2AF0DAC05D3F3E0EFA32A`. Verify commits with `git verify-commit HEAD`.
