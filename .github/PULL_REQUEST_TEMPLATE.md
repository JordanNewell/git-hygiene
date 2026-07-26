## Summary

One or two sentences. What does this PR change and why?

## Motivation

Link the issue this closes (e.g. `Closes #123`), or describe the problem.

## Type of change

- [ ] Bug fix (non-breaking)
- [ ] New OPSEC pattern / scanner rule
- [ ] Improvement to existing hook
- [ ] Refactor (no behavior change)
- [ ] Documentation
- [ ] Breaking change

## Checklist

- [ ] I have read [CONTRIBUTING.md](../blob/main/CONTRIBUTING.md)
- [ ] `shellcheck hooks/*.sh` clean
- [ ] Hook tested manually against a representative commit
- [ ] If new OPSEC pattern: added fixture under `patterns/` or `tests/`
- [ ] README updated if user-facing behavior changed
- [ ] Commits signed
- [ ] **No AI-attribution trailers** (`Co-Authored-By: Claude`, `Generated-by`, etc.)

## Test plan

How did you verify this works? Paste the hook invocations and observed output against sanitized test fixtures.

```sh
$ shellcheck hooks/*.sh
$ # exercise the hook against a test commit
```