#!/bin/bash
# opsec-scan.sh — sourceable library that builds $opsec_patterns from
# machine-level and repo-local sources. Designed to be sourced by:
#   - commit-msg hooks (scan subject line for sensitive tokens)
#   - voice-lint / content linters (scan prose for leaks)
#
# Usage:
#   source /path/to/opsec-scan.sh
#   if echo "$some_text" | grep -qE "$opsec_patterns"; then
#     echo "OPSEC leak detected" >&2
#     exit 1
#   fi
#
# Pattern sources (first to last wins; later sources extend, not override):
#   1. Hardcoded baseline (below) — universal, safe for public repos
#   2. Machine-level  — $HOME/.config/opsec-patterns.local  (gitignored, real values)
#   3. Repo-local     — ./.opsec-patterns.local             (gitignored, repo-specific extras)
#
# The .local files are gitignored by convention. They contain real hostnames,
# tailnet name, agent handles, codenames — values that are OPSEC-sensitive
# themselves. See opsec-patterns.local.example for the contract.

# Hardcoded baseline — universally concerning patterns only:
#   - Session IDs (Sxxx convention — common in internal ops)
#   - Tailscale CGNAT IPs (100.x.x.x — anyone using Tailscale)
# Machine-specific patterns (hostnames, tailnet name, agent handles) belong
# in the user's ~/.config/opsec-patterns.local, NOT in this baseline.
#
# If the caller has already set $opsec_patterns (e.g. blog voice-lint with
# repo-specific paths), we EXTEND it rather than overwriting. Set
# OPSEC_SCAN_RESET=1 to force a clean baseline instead.
if [ -z "${opsec_patterns:-}" ] || [ "${OPSEC_SCAN_RESET:-0}" = "1" ]; then
  opsec_patterns='\bS[0-9]{3}\b|100\.[0-9]{1,3}(\.[0-9]{1,3}){2}'
fi

# Layer in machine-level real values (hostnames, tailnet, agent handles, codenames)
_opsec_local_file="$HOME/.config/opsec-patterns.local"
if [ -f "$_opsec_local_file" ]; then
  _opsec_local="$(grep -vE '^[[:space:]]*(#|$)' "$_opsec_local_file" | paste -sd'|' -)"
  if [ -n "$_opsec_local" ] && [ -n "$opsec_patterns" ]; then
    opsec_patterns="${opsec_patterns}|\b(${_opsec_local})\b"
  elif [ -n "$_opsec_local" ]; then
    opsec_patterns="\b(${_opsec_local})\b"
  fi
fi

# Layer in repo-local extras (optional — for project-specific patterns that
# don't apply machine-wide)
_opsec_repo_file="./.opsec-patterns.local"
if [ -f "$_opsec_repo_file" ]; then
  _opsec_repo="$(grep -vE '^[[:space:]]*(#|$)' "$_opsec_repo_file" | paste -sd'|' -)"
  if [ -n "$_opsec_repo" ] && [ -n "$opsec_patterns" ]; then
    opsec_patterns="${opsec_patterns}|\b(${_opsec_repo})\b"
  elif [ -n "$_opsec_repo" ]; then
    opsec_patterns="\b(${_opsec_repo})\b"
  fi
fi

# Per-repo opt-out: `git config opsec.scan disable`
#
# Use case: internal repos whose subjects reference internal codenames
# (agent handles, hostnames, project codenames) legitimately. Without an
# opt-out, the scan would reject every internal-style commit.
#
# Opt-out is scoped to this repo only (lives in .git/config, never committed).
# Disables the OPSEC pattern scan ONLY — AI-attribution strip in commit-msg
# and the secret scan in pre-commit are unaffected.
#
# Value normalization: the git config value is lowercased and matched against
# a set of boolean-style synonyms (disable/off/false/no/0). Aligns with git's
# own boolean conventions so 'Disable', 'DISABLE', 'off', etc. all trigger
# the opt-out. Literal 'true'/'yes'/'1'/'enable' do NOT match the opt-out
# case set, so they leave patterns intact (the default behavior).
#
# Applied last so it cleanly overrides all layered patterns. Only honor the
# opt-out when inside a git work tree — when sourced by a standalone linter
# (e.g. voice-lint on a markdown file outside a repo), `git config` would
# fail noisily; the 2>/dev/null handles that gracefully.
if [ -n "${opsec_patterns:-}" ]; then
  # `|| true` defends against `set -euo pipefail` in the sourcing hook —
  # git config fails harmlessly when not inside a repo (standalone linters).
  _opsec_decision="$(git config opsec.scan 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  case "$_opsec_decision" in
    disable|off|false|no|0) opsec_patterns="" ;;
  esac
  unset _opsec_decision
fi

unset _opsec_local_file _opsec_local _opsec_repo_file _opsec_repo
