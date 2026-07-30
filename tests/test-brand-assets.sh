#!/bin/bash
# tests/test-brand-assets.sh — validate rendered NEWELL brand assets.
#
# Asserts: every expected file exists, is non-empty, has the expected
# dimensions (via `file` if available; advisory only).
#
# Zero dependencies beyond bash + the standard `file` utility (optional).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$REPO_ROOT/docs/assets"
FAV="$ASSETS/favicons"

PASS=0
FAIL=0
FAILED_NAMES=()

pass() { PASS=$((PASS + 1)); }

fail() {
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("$1")
    echo "  ✗ $1" >&2
}

assert_file_exists() {
    local name="$1" path="$2"
    if [ -f "$path" ] && [ -s "$path" ]; then
        pass
    else
        fail "$name — missing or empty: $path"
    fi
}

assert_dimensions() {
    local name="$1" path="$2" expected="$3"
    if ! command -v file >/dev/null 2>&1; then
        return 0  # advisory only — skip if file(1) unavailable
    fi
    local actual
    actual=$(file "$path" 2>/dev/null | grep -oE '[0-9]+ x [0-9]+' | head -1)
    if [ -n "$actual" ] && [ "$actual" = "$expected" ]; then
        pass
    else
        fail "$name — dimensions '$actual' (expected '$expected')"
    fi
}

# ---------- OG card ----------

assert_file_exists        "OG card exists"        "$ASSETS/og.png"
assert_dimensions         "OG card 1200x630"      "$ASSETS/og.png"   "1200 x 630"

# ---------- Favicons ----------

assert_file_exists        "favicon-16 exists"     "$FAV/favicon-16.png"
assert_dimensions         "favicon-16 16x16"      "$FAV/favicon-16.png"   "16 x 16"

assert_file_exists        "favicon-32 exists"     "$FAV/favicon-32.png"
assert_dimensions         "favicon-32 32x32"      "$FAV/favicon-32.png"   "32 x 32"

assert_file_exists        "favicon-64 exists"     "$FAV/favicon-64.png"
assert_dimensions         "favicon-64 64x64"      "$FAV/favicon-64.png"   "64 x 64"

assert_file_exists        "apple-touch-icon exists"  "$FAV/apple-touch-icon.png"
assert_dimensions         "apple-touch-icon 180x180" "$FAV/apple-touch-icon.png"  "180 x 180"

assert_file_exists        "favicon.ico exists"    "$FAV/favicon.ico"

# ---------- Summary ----------

echo
echo "Brand assets: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    for n in "${FAILED_NAMES[@]}"; do echo "  ✗ $n"; done
    exit 1
fi
exit 0
