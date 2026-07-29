# Tests

Pure-bash test suite for `commit-msg` and `pre-commit` hooks. Zero dependencies beyond what the hooks themselves use (bash, git, grep, awk, mktemp).

## Run

```bash
bash tests/run-tests.sh
```

Exit code `0` = all tests passed. Non-zero = at least one failure (details printed to stderr).

## What's covered

**`commit-msg`** (32 tests)
- Strips every AI-attribution trailer pattern (Claude / Copilot / Cursor / Gemini / ChatGPT / ZCode / Z.ai / GLM / Bigmodel, plus `Generated with`, `Generated-with:`, `AI-assisted:`, `Written by`, `Created by`, and bare `noreply@anthropic.com` / `noreply@z.ai` / `noreply@github.com` copilot).
- Preserves legitimate human co-authors, prose mentions, `Reviewed-by:`, `Signed-off-by:`, issue refs.
- OPSEC scan on subject line (session IDs `Sxxx`, Tailscale CGNAT IPs `100.x.x.x`), with opt-out via `git config opsec.scan disable`.
- Body OPSEC mentions are NOT scanned (preserves legitimate prose).
- Blank-line collapse after strip; no leading blank line in body.

**`pre-commit`** (51 tests)
- Layer 1 regex blocks every known secret shape (AWS `AKIA`, `sk-or-`, GitHub `ghp_/gho_/ghu_/ghs_/ghr_/github_pat_`, Slack `xox[bp]-`, Bearer, `api_key=`, `secret=`, `password=`, `token=`).
- Does NOT block clean content or short strings below the regex length floor.
- Path skipping exempts `node_modules/`, `vendor/`, `third_party/`, `*.min.{js,css}`, `test[s]/`, `__tests__/`, `spec/`, `fixtures/`, `*.test.*`, `*.spec.*`, `example[s]/`, `docs/`, `*.example`, `*.template`, `*.dist`.
- Empty stage exits 0 immediately.

Layers 2 (gitleaks) and 3 (OPSEC content scan) are environment-dependent and not exercised here — they degrade gracefully when their inputs (gitleaks binary / `.local` pattern files) are absent.

## Extend

Each test is a one-line entry in a `cases=(...)` array (for table-driven tests) or a small block calling the `assert_*` helpers. To add a new pattern to `commit-msg`, add a line to `suite_commit_msg_strip`. To add a new secret shape to `pre-commit`, add an `expect_blocks` call.
