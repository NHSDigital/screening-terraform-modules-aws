# Guide: Run Git hooks on commit

- [Guide: Run Git hooks on commit](#guide-run-git-hooks-on-commit)
  - [Overview](#overview)
  - [Setup](#setup)
  - [Key files](#key-files)
  - [Testing](#testing)
  - [Need Help?](#need-help)

## Overview

Git hooks are scripts that run automatically on each commit, helping to ensure code consistency and catch errors early. This repository uses the [pre-commit](https://pre-commit.com/) framework for managing hooks efficiently.

In CI/CD, coding checks are executed via the `stage-1-pre-commit.yml` GitHub Actions workflow. The same hooks run locally before you commit, catching issues before they reach GitHub.

## Setup

### Prerequisites

Install required tools via `mise` (see [README.md](../../README.md#prerequisites)):

```bash
mise install
```

### Install Hooks

```bash
# Run once after cloning the repository
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

### Verify Installation

```bash
pre-commit run --all-files
```

This command runs hooks assigned to the `pre-commit` stage. The Conventional Commit validator runs separately during `git commit` at the `commit-msg` stage.

If you want the complete history secret scan locally, run it explicitly:

```bash
pre-commit run scan-secrets-whole-history --hook-stage manual --all-files
```

If successful, output ends with:

```text
====== Summary =====
Passed: X, Failed: 0, Skipped: Y
```

## Key files

| File | Purpose |
| --- | --- |
| `.pre-commit-config.yaml` | Defines all 26 hooks (Terraform, shell scripts, security, formatting, commit messages) |
| `scripts/githooks/` | Custom hook implementations (format checking, secret scanning, validation) |
| `.vale.ini` | English style rules (British English, NHS terminology) |
| `.tflint.hcl` | Terraform linting rules |

## Testing

Run hooks locally to validate code before committing:

```bash
# Test all pre-commit stage hooks on the entire repository
pre-commit run --all-files

# Test the full-history secret scan explicitly
pre-commit run scan-secrets-whole-history --hook-stage manual --all-files

# Test a specific hook
pre-commit run terraform_fmt --all-files
pre-commit run shellcheck --all-files
```

## Need Help?

For comprehensive documentation on each hook, including troubleshooting and fixes:

→ **[Pre-Commit Hooks Reference Guide](Pre_commit_hooks_reference.md)** — Detailed guide to all 26 hooks, common failures, and remediation steps.

For AI agent guidance and advanced scenarios, see `.github/skills/pre-commit-hooks.skill.md`.
