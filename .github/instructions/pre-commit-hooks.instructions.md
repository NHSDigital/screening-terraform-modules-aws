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
| Dependabot config out of sync | Commit the regenerated `.github/dependabot.yaml` (auto-generated) |
| Available modules table out of sync | Commit the regenerated `README.md` Available modules section (auto-generated). Includes all modules: regular modules alphabetically, then legacy modules (older format, in `_legacy/`) with `[LEGACY]` markers at the end. |
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
- `scan-secrets-staged-changes` — scans staged changes for secrets (runs on `git commit`)
- `scan-secrets-whole-history` — scans entire git history for secrets (runs on `pre-commit run --all-files`)
- `terraform_validate` — ensures modules are syntactically valid
- `regenerate-dependabot-config` — ensures Dependabot watches all modules
- `check-available-modules` — ensures README module table is up-to-date
- `no-commit-to-branch` — enforces PR workflow

## Tool Invocation in Scripts

When writing shell scripts that invoke tools (especially in pre-commit hooks), always wrap tool invocations with `mise x --` to ensure the correct version is used:

```bash
# Good: Uses mise-managed tool version
mise x -- yq eval '.' config.yaml
mise x -- actionlint .github/workflows/*.yml

# Avoid: May use system version (syntax differences between implementations)
yq eval '.' config.yaml
actionlint .github/workflows/*.yml
```

**Why?** Different implementations (e.g., Go vs Python versions of yq) have different CLI syntax. Using `mise x --` guarantees version consistency across environments and prevents subtle failures.

## Need Help?

See `.github/skills/pre-commit-hooks.skill.md` for detailed documentation on each hook.

## Force Skip (Emergency Only)

```bash
git commit --no-verify
```

⚠️ **CRITICAL:** Never use `--no-verify` to skip security checks. Report the issue immediately.
