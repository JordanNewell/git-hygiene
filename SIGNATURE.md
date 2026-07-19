# Signature

This repo follows the [Jordan Newell code-signature pattern](https://jordannewell.com/signature/). Three layers.

## Layer 1 — Style tells

Headline-first docstrings, why-only comments, causality test naming, headline function first. This repo is mostly shell scripts so the style tells are lighter (shell conventions vary), but the principle holds.

## Layer 2 — `__signature__` constant

N/A — shell scripts don't export a Python-style `__signature__`. The repo itself is the signature: small, focused, MIT, no dependencies beyond coreutils.

## Layer 3 — PGP-signed commits and tags

All commits and tags signed with Jordan's signing key. Fingerprint:

```
67567DC5E7C5353F85F2AF0DAC05D3F3E0EFA32A
```

Key ID: `AC05D3F3E0EFA32A`. Type: Ed25519, expiry 2 years.

Retrieve via Web Key Directory:

```bash
gpg --auto-key-locate clear,dkd,nodefault --locate-key jordan@jordannewell.com
```

Or from a keyserver:

```bash
gpg --keyserver hkps://keys.openpgp.org      --recv-keys AC05D3F3E0EFA32A
gpg --keyserver hkps://keyserver.ubuntu.com  --recv-keys AC05D3F3E0EFA32A
```

Verify a commit:

```bash
git clone https://github.com/JordanNewell/git-hygiene.git
cd git-hygiene
git verify-commit HEAD
```
