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
  if [ -n "$_opsec_local" ]; then
    opsec_patterns="${opsec_patterns}|\b(${_opsec_local})\b"
  fi
fi

# Layer in repo-local extras (optional — for project-specific patterns that
# don't apply machine-wide)
_opsec_repo_file="./.opsec-patterns.local"
if [ -f "$_opsec_repo_file" ]; then
  _opsec_repo="$(grep -vE '^[[:space:]]*(#|$)' "$_opsec_repo_file" | paste -sd'|' -)"
  if [ -n "$_opsec_repo" ]; then
    opsec_patterns="${opsec_patterns}|\b(${_opsec_repo})\b"
  fi
fi

unset _opsec_local_file _opsec_local _opsec_repo_file _opsec_repo
