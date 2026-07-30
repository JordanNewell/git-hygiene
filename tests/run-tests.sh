#!/bin/bash
# tests/run-tests.sh — pure-bash test suite for git-hygiene hooks
#
# Zero dependencies beyond bash + git + the tools the hooks themselves use
# (grep, awk, mktemp). Runs on Linux, macOS, and Windows Git Bash.
#
# Run: bash tests/run-tests.sh
# Exit: 0 if all tests pass, 1 if any fail.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/hooks"

# Counters
PASS=0
FAIL=0
FAILED_NAMES=()

# ---------- helpers ----------

pass() { PASS=$((PASS + 1)); }

fail() {
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("$1")
    echo "  ✗ $1" >&2
}

# assert_exit <expected> <name> <cmd...>
assert_exit() {
    local expected=$1 name="$2"
    shift 2
    "$@" >/dev/null 2>&1
    local actual=$?
    if [ "$actual" -eq "$expected" ]; then
        pass
    else
        fail "$name (expected exit=$expected actual=$actual)"
    fi
}

# assert_file_contains <file> <needle> <name>
assert_file_contains() {
    if grep -qF "$2" "$1" 2>/dev/null; then
        pass
    else
        fail "$3 (missing: $2)"
    fi
}

# assert_file_not_contains <file> <needle> <name>
assert_file_not_contains() {
    if grep -qF "$2" "$1" 2>/dev/null; then
        fail "$3 (should not contain: $2)"
    else
        pass
    fi
}

# run_commit_msg <message-stdin> — writes message to temp file, runs commit-msg,
# leaves $MSG_FILE set so the caller can inspect the result. Cleans up on EXIT.
run_commit_msg() {
    MSG_FILE="$(mktemp)"
    printf '%s' "$1" > "$MSG_FILE"
    bash "$HOOKS_DIR/commit-msg" "$MSG_FILE"
}

# setup_test_repo — creates a temp git repo wired to use the project's hooks.
# Echoes the repo path. Caller must clean up via `rm -rf $REPO`.
setup_test_repo() {
    local repo
    repo="$(mktemp -d)"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@test.local"
    git -C "$repo" config user.name "Test"
    git -C "$repo" config commit.gpgsign false
    git -C "$repo" config core.hooksPath "$HOOKS_DIR"
    echo "$repo"
}

# ---------- commit-msg tests ----------

suite_commit_msg_strip() {
    echo "## commit-msg · strips AI-attribution trailers"
    local cases=(
        "Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>|claude co-author"
        "Co-Authored-By: Copilot <noreply@github.com>|copilot co-author"
        "Co-Authored-By: Cursor <noreply@cursor.sh>|cursor co-author"
        "Co-Authored-By: Gemini <noreply@google.com>|gemini co-author"
        "Co-Authored-By: ChatGPT <noreply@openai.com>|chatgpt co-author"
        "Co-Authored-By: GitHub Copilot <noreply@github.com>|github copilot co-author"
        "Co-Authored-By: Something <noreply@anthropic.com>|anthropic domain"
        "Co-Authored-By: Foo <AI|AI bracket"
        "Co-Authored-By: Foo Bar (AI assistant)|AI word"
        "Co-Authored-By: ZCode Agent <noreply@z.ai>|zcode"
        "Co-Authored-By: Foo <noreply@z.ai>|z.ai domain"
        "Co-Authored-By: GLM <noreply@bigmodel.cn>|glm"
        "Co-Authored-By: Bigmodel <noreply@bigmodel.cn>|bigmodel"
        "Co-Authored-By: BigModel <noreply@bigmodel.cn>|bigmodel capital"
        "Generated with Claude Code|generated-with claude"
        "Generated with Copilot|generated-with copilot"
        "Generated with Cursor|generated-with cursor"
        "Generated with Gemini|generated-with gemini"
        "Generated with ZCode|generated-with zcode"
        "Generated with GLM|generated-with glm"
        "Generated-with: Claude Code|generated-with hyphen"
        "AI-assisted: 60%|ai-assisted"
        "Written by Claude|written by claude"
        "Created by Claude|created by claude"
        "noreply@anthropic.com|bare anthropic email"
        "noreply@z.ai|bare z.ai email"
        "noreply@github.com/copilot|bare copilot email"
    )
    local case name
    for case in "${cases[@]}"; do
        name="${case##*|}"
        case="${case%|*}"
        run_commit_msg "test subject

$case" >/dev/null 2>&1 || true
        assert_file_not_contains "$MSG_FILE" "$case" "strip: $name"
        rm -f "$MSG_FILE"
    done
}

suite_commit_msg_preserve() {
    echo "## commit-msg · preserves legitimate content"
    local cases=(
        "Co-Authored-By: Jane Doe <jane@example.com>|human co-author"
        "Co-Authored-By: Bob Smith <bob@example.com>|human co-author 2"
        "Co-Authored-By: Alice <alice@corp.com>|human co-author 3"
        "the Claude Code agent was mangling whitespace|prose mention"
        "we use AI internally for some boilerplate|prose AI"
        "Reviewed-by: Jane <jane@x.com>|other trailer"
        "Signed-off-by: Jordan <jordan@jordannewell.com>|DCO signoff"
        "Fixes #123|issue ref"
    )
    local case name
    for case in "${cases[@]}"; do
        name="${case##*|}"
        case="${case%|*}"
        run_commit_msg "test subject

$case" >/dev/null 2>&1 || true
        assert_file_contains "$MSG_FILE" "$case" "preserve: $name"
        rm -f "$MSG_FILE"
    done
}

suite_commit_msg_opsec() {
    echo "## commit-msg · OPSEC scan on subject line"

    # Session ID pattern (Sxxx)
    MSG_FILE="$(mktemp)"
    printf 'S100: fleet ops tweak\n\nbody' > "$MSG_FILE"
    assert_exit 1 "OPSEC: S100 in subject" bash "$HOOKS_DIR/commit-msg" "$MSG_FILE"
    rm -f "$MSG_FILE"

    # Tailscale CGNAT IP
    MSG_FILE="$(mktemp)"
    printf 'fix ssh to 100.64.0.1\n\nbody' > "$MSG_FILE"
    assert_exit 1 "OPSEC: CGNAT IP in subject" bash "$HOOKS_DIR/commit-msg" "$MSG_FILE"
    rm -f "$MSG_FILE"

    # Clean subject — exit 0
    MSG_FILE="$(mktemp)"
    printf 'fix whitespace in README\n\nbody' > "$MSG_FILE"
    assert_exit 0 "OPSEC: clean subject passes" bash "$HOOKS_DIR/commit-msg" "$MSG_FILE"
    rm -f "$MSG_FILE"

    # OPSEC pattern in body (not subject) — should pass (bodies not scanned)
    MSG_FILE="$(mktemp)"
    printf 'normal subject\n\nDiscussed in S100 standup.' > "$MSG_FILE"
    assert_exit 0 "OPSEC: body mentions are not scanned" bash "$HOOKS_DIR/commit-msg" "$MSG_FILE"
    rm -f "$MSG_FILE"

    # OPSEC scan opt-out via git config — needs a real repo to honor config
    local repo
    repo="$(setup_test_repo)"
    git -C "$repo" config opsec.scan disable
    git -C "$repo" commit --allow-empty -m "S100: ops tweak" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        pass
    else
        fail "OPSEC: opsec.scan=disable should allow S100 subject"
    fi
    rm -rf "$repo"
}

suite_commit_msg_blank_collapse() {
    echo "## commit-msg · collapses blank lines"

    MSG_FILE="$(mktemp)"
    printf 'subject\n\n\n\n\nbody line 1\n\n\n\nbody line 2' > "$MSG_FILE"
    bash "$HOOKS_DIR/commit-msg" "$MSG_FILE" >/dev/null 2>&1 || true
    # Result should have at most one blank line between content lines.
    local blanks
    blanks=$(awk '/^$/{c++; next} {if(c>max)max=c; c=0} END{print max+0}' "$MSG_FILE")
    if [ "${blanks:-0}" -le 1 ]; then
        pass
    else
        fail "blank collapse (max run of $blanks)"
    fi
    rm -f "$MSG_FILE"

    # Stripping trailers should not leave leading blank line at top of body
    MSG_FILE="$(mktemp)"
    printf 'subject\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n\nbody' > "$MSG_FILE"
    bash "$HOOKS_DIR/commit-msg" "$MSG_FILE" >/dev/null 2>&1 || true
    if head -2 "$MSG_FILE" | tail -1 | grep -q '^$' && head -3 "$MSG_FILE" | tail -1 | grep -q '^body'; then
        pass
    else
        fail "no leading blank after strip"
    fi
    rm -f "$MSG_FILE"
}

# ---------- pre-commit tests ----------

# Test a single secret pattern. Args: <pattern-name> <content>
expect_blocks() {
    local name="$1" content="$2"
    local repo file
    repo="$(setup_test_repo)"
    file="$repo/file.txt"
    printf '%s\n' "$content" > "$file"
    git -C "$repo" add file.txt 2>/dev/null
    if git -C "$repo" commit -m "test" >/dev/null 2>&1; then
        fail "Layer 1 did NOT block: $name"
    else
        pass
    fi
    rm -rf "$repo"
}

# Test a single secret pattern in a SKIPPED path — must NOT block.
expect_skipped() {
    local name="$1" relative_path="$2" content="$3"
    local repo dir file
    repo="$(setup_test_repo)"
    dir="$repo/$(dirname "$relative_path")"
    mkdir -p "$dir"
    file="$repo/$relative_path"
    printf '%s\n' "$content" > "$file"
    git -C "$repo" add "$relative_path" 2>/dev/null
    if git -C "$repo" commit -m "test" >/dev/null 2>&1; then
        pass
    else
        fail "Layer 1 wrongly blocked skipped path: $name"
    fi
    rm -rf "$repo"
}

suite_pre_commit_secret_patterns() {
    echo "## pre-commit · Layer 1 regex blocks known secret shapes"

    expect_blocks "AWS access key"         'AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE'
    expect_blocks "AWS access key (raw)"   'key=AKIAIOSFODNN7EXAMPLE'
    expect_blocks "AWS secret key"         'AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    expect_blocks "OpenAI (sk-or-)"        'sk-or-'$(printf 'a%.0s' {1..48})
    expect_blocks "GitHub ghp_"            'ghp_'$(printf 'a%.0s' {1..36})
    expect_blocks "GitHub gho_"            'gho_'$(printf 'a%.0s' {1..36})
    expect_blocks "GitHub ghu_"            'ghu_'$(printf 'a%.0s' {1..36})
    expect_blocks "GitHub ghs_"            'ghs_'$(printf 'a%.0s' {1..36})
    expect_blocks "GitHub ghr_"            'ghr_'$(printf 'a%.0s' {1..36})
    expect_blocks "GitHub PAT"             'github_pat_'$(printf 'a%.0s' {1..82})
    expect_blocks "Slack xoxb-"            'xoxb-1234567890123-1234567890123-'$(printf 'a%.0s' {1..24})
    expect_blocks "Slack xoxp-"            'xoxp-1234567890123-1234567890123-1234567890123-'$(printf 'a%.0s' {1..32})
    expect_blocks "AKIA (raw)"             'value=AKIAIOSFODNN7EXAMPLE'
    expect_blocks "Bearer token"           'Authorization: Bearer '$(printf 'a%.0s' {1..48})
    expect_blocks "api_key assignment"     'api_key="abcdef0123456789abcdef0123456789"'
    expect_blocks "secret assignment"      'secret="abcdef0123456789abcdef0123456789"'
    expect_blocks "token assignment"       'token="abcdef0123456789abcdef0123456789"'
    expect_blocks "password (long enough)" 'password="supersecretpw"'
}

suite_pre_commit_negative() {
    echo "## pre-commit · Layer 1 does NOT block clean content"

    local repo
    repo="$(setup_test_repo)"
    printf 'just a normal config file\nport=8080\nhost=localhost\n' > "$repo/config.txt"
    git -C "$repo" add config.txt
    if git -C "$repo" commit -m "add config" >/dev/null 2>&1; then
        pass
    else
        fail "clean content blocked"
    fi

    # Short password (under 8 chars) — should NOT match (regex needs 8+)
    printf 'password=short\n' > "$repo/short.txt"
    git -C "$repo" add short.txt
    if git -C "$repo" commit -m "short" >/dev/null 2>&1; then
        pass
    else
        fail "short password wrongly blocked"
    fi

    # Short secret (under 32 chars) — should NOT match
    printf 'token=abc\n' > "$repo/tiny.txt"
    git -C "$repo" add tiny.txt
    if git -C "$repo" commit -m "tiny" >/dev/null 2>&1; then
        pass
    else
        fail "short token wrongly blocked"
    fi

    rm -rf "$repo"
}

suite_pre_commit_path_skip() {
    echo "## pre-commit · Layer 1 skips fixture / vendor / example paths"

    local secret='AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE'

    expect_skipped "node_modules"      'node_modules/pkg/index.js' "$secret"
    expect_skipped "nested node_modules" 'app/node_modules/pkg/index.js' "$secret"
    expect_skipped "vendor"            'vendor/lib/foo.js' "$secret"
    expect_skipped "third_party"       'third_party/foo.c' "$secret"
    expect_skipped "*.min.js"          'bundle.min.js' "$secret"
    expect_skipped "*.min.css"         'styles.min.css' "$secret"
    expect_skipped "test/"             'test/foo.test.js' "$secret"
    expect_skipped "tests/"            'tests/foo.test.js' "$secret"
    expect_skipped "__tests__/"        '__tests__/foo.test.js' "$secret"
    expect_skipped "spec/"             'spec/foo.spec.js' "$secret"
    expect_skipped "fixtures/"         'fixtures/sample.json' "$secret"
    expect_skipped "*.test.js"         'foo.test.js' "$secret"
    expect_skipped "*.spec.js"         'foo.spec.js' "$secret"
    expect_skipped "example/"          'example/demo.js' "$secret"
    expect_skipped "examples/"         'examples/demo.js' "$secret"
    expect_skipped "docs/"             'docs/guide.md' "$secret"
    expect_skipped "*.example"         'config.example' "$secret"
    expect_skipped "*.template"        'config.template' "$secret"
    expect_skipped "*.dist"            'config.dist' "$secret"
}

suite_pre_commit_empty_stage() {
    echo "## pre-commit · empty stage exits 0"

    local repo
    repo="$(setup_test_repo)"
    # Empty stage — invoking the hook directly should exit 0
    assert_exit 0 "empty stage" bash "$HOOKS_DIR/pre-commit"
    rm -rf "$repo"
}

# ---------- main ----------

echo "git-hygiene hook test suite"
echo "----------------------------"
echo ""

suite_commit_msg_strip
suite_commit_msg_preserve
suite_commit_msg_opsec
suite_commit_msg_blank_collapse
suite_pre_commit_secret_patterns
suite_pre_commit_negative
suite_pre_commit_path_skip
suite_pre_commit_empty_stage

# ---------- NEWELL brand assets ----------

if bash "$(dirname "$0")/test-brand-assets.sh"; then
    :
else
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("brand-assets-suite")
fi

echo ""
echo "----------------------------"
echo "  pass: $PASS"
echo "  fail: $FAIL"
echo "----------------------------"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "Failed tests:"
    for name in "${FAILED_NAMES[@]}"; do
        echo "  - $name"
    done
    exit 1
fi

exit 0
