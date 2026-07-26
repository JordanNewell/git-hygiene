# Security Policy

## Supported versions

Only the latest release receives security updates.

## Reporting a vulnerability

Email **security@jordannewell.com** with:

- A description of the issue and its impact
- Reproduction steps (a minimal example is ideal)
- Affected version — run `git-hygiene --version`

**Do not open a public GitHub issue** for security reports.

## Response timeline

- **Acknowledgement:** within 48 hours
- **Initial assessment:** within 5 business days
- **Fix or mitigation:** target 30 days for high-severity issues

Please refrain from public disclosure until a fix has been published, to
protect downstream users. Reporters will be credited in the release notes
unless they prefer otherwise.

## Scope

**In scope:**

- The bash scripts
- The OPSEC pattern matcher
- Attribution stripping logic
- Reports about bypasses or false negatives in the pattern matcher are
  particularly welcome — this is a security tool itself, so gaps in its
  detection coverage are valid findings

**Out of scope:**

- git itself — report upstream
- Dependencies (gitleaks, trufflehog) — those have their own security
  policies; report findings there