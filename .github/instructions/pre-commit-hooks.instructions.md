---
applyTo: "*"
---

# Pre-Commit Hooks Instructions

Pre-commit hooks are mandatory quality gates that run automatically on every commit. All hooks must pass before code can be pushed.

## Installation

```bash
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

## Common Hooks & Quick Fixes

| Issue | Fix |
| --- | --- |
| Terraform format mismatch | `terraform fmt -recursive infrastructure/modules/` |
| Documentation out of sync | `pre-commit run terraform_docs --all-files` |
| Shell script errors | Review output; fix syntax errors; re-run `pre-commit run shellcheck` |
| English/spelling mistakes | Check `.vale.ini` rules; update text if needed |
| Trailing whitespace/EOL | `pre-commit run --all-files` (auto-fixed) |
| Commit message format | Use `feat(scope): description` format; see Conventional Commits guidance |

## Before Committing

```bash
# Run all hooks locally
pre-commit run --all-files

# Fix any issues reported

# Stage and commit
git add .
git commit -m "type(scope): description"
```

## Never Skip These Hooks

- `detect-aws-credentials` — detects embedded secrets
- `detect-private-key` — detects leaked private keys
- `scan-secrets` — scans git history for secrets
- `terraform_validate` — ensures modules are syntactically valid
- `no-commit-to-branch` — enforces PR workflow

## Need Help?

See `.github/skills/pre-commit-hooks.skill.md` for detailed documentation on each hook.

## Force Skip (Emergency Only)

```bash
git commit --no-verify
```

⚠️ **CRITICAL:** Never use `--no-verify` to skip security checks. Report the issue immediately.
