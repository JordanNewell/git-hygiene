---
name: Bug Report
about: Report a bug in git-hygiene to help us improve
title: "[BUG] "
labels: ["bug", "triage"]
assignees: []
---

## Bug description

A clear description of what's broken.

## Steps to reproduce

1.
2.
3.

## Expected behavior

What you thought would happen.

## Actual behavior

What actually happened.

## Triggering commit message / OPSEC pattern

For false positives from the OPSEC scan, paste the **sanitized** commit message that triggered the finding (redact any real secrets, internal hostnames, or agent handles first) and the pattern it tripped.

```
paste sanitized commit message here
```

Pattern matched: (e.g. `userve*`, agent handle, key shape, etc.)

## Environment

- **git-hygiene version:** (commit SHA or tag if pinned; otherwise "latest main")
- **OS:** (Ubuntu 24.04 / macOS 14 / Windows 11)
- **Shell:** (bash / zsh / dash — output of `echo $SHELL`)
- **git version:** output of `git --version`
- **Dependencies installed:** (gitleaks / trufflehog / shellcheck / none)

## Logs / screenshots

Paste relevant hook output and any screenshots.

```
paste output here
```

## Self-check

- [ ] I have searched existing issues for duplicates.
- [ ] I have sanitized any sensitive data (hostnames, agent handles, secrets).
- [ ] This is not a security issue (those go through [SECURITY.md](../blob/main/SECURITY.md) privately).