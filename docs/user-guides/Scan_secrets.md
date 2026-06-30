# Guide: Scan secrets

- [Guide: Scan secrets](#guide-scan-secrets)
  - [Overview](#overview)
  - [Two-tier scanning: Staged changes + Complete history](#two-tier-scanning-staged-changes--complete-history)
  - [Key files](#key-files)
  - [Configuration checklist](#configuration-checklist)
  - [Testing](#testing)
  - [Removing sensitive data](#removing-sensitive-data)

## Overview

Scanning a repository for hard-coded secrets is a crucial security practice. "Hard-coded secrets" pertain to sensitive data such as passwords, API keys and encryption keys that are embedded directly into the code. This practice is strongly discouraged as it may lead to security incidents.

[Gitleaks](https://github.com/gitleaks/gitleaks) is a powerful open-source tool designed to identify hard-coded secrets and other sensitive information in Git repositories. It works by scanning the commit history and the working directory for sensitive data that should not be there.

## Two-tier scanning: Staged changes + Complete history

This repository uses two complementary secret scanning hooks to provide defense in depth:

### `scan-secrets-staged-changes`

- **When:** Runs automatically on `git commit` before the commit is created
- **Scope:** Scans only the files you're about to commit (staged changes)
- **Purpose:** Fast feedback loop — catches secrets before they enter the repository
- **Time:** ~1 second (very fast)

**Fix immediately if it triggers:**

```bash
# Unstage the file
git reset .env

# Remove or edit to remove the secret
# Then stage and commit the corrected version
git add .env
git commit -m "fix: remove secret"
```

### `scan-secrets-whole-history`

- **When:** Runs only when explicitly invoked with the `manual` stage or in CI/CD pipelines
- **Scope:** Scans entire git history (all commits)
- **Purpose:** Comprehensive audit — catches secrets that may have been committed before this hook existed
- **Time:** ~10-30 seconds (slower, but thorough)

**Run manually:**

```bash
# Full history scan (use before pushing to remote)
check=whole-history ./scripts/githooks/scan-secrets.sh

# Or via pre-commit
pre-commit run scan-secrets-whole-history --hook-stage manual --all-files
```

**If it fails:** Secret is already in history; see [Removing sensitive data](#removing-sensitive-data) below for remediation.

## Key files

- [`scan-secrets.sh`](../../scripts/githooks/scan-secrets.sh): A shell script that scans the codebase for hard-coded secrets (supports `check=staged-changes` and `check=whole-history` modes)
- [`gitleaks.toml`](../../scripts/config/gitleaks.toml): A configuration file for the secret scanner
- [`.gitleaksignore`](../../.gitleaksignore): A list of fingerprints to ignore by the secret scanner
- [`scan-secrets/action.yaml`](../../.github/actions/scan-secrets/action.yaml): GitHub action to run the scripts as part of the CI/CD pipeline

## Configuration checklist

- [Add custom secret patterns](../../scripts/config/gitleaks.toml) to the configuration file to align with your project's specific requirements
- [Create a secret scan baseline](https://github.com/gitleaks/gitleaks/blob/master/README.md#gitleaksignore) for your repository by adding false-positive fingerprints to the ignore list
- Ensure that the GitHub action, which incorporates Gitleaks, forms part of your GitHub CI/CD workflow. It is designed to run a full scan as a part of the pipeline, providing additional protection against hard-coded secrets that might have been included prior to the rule additions or by bypassing the scanner
- Further details on this topic can be found in the [decision record](https://github.com/nhs-england-tools/repository-template/blob/main/docs/adr/ADR-002_Scan_repository_for_hardcoded_secrets.md) as well as in the [NHSE Software Engineering Quality Framework](https://github.com/NHSDigital/software-engineering-quality-framework/tree/main/tools/nhsd-git-secrets) where a usage of an alternative tool is shown

## Testing

You can execute and test the secret scanning locally on a developer's workstation:

**Staged changes only (fast):**

```bash
check=staged-changes ./scripts/githooks/scan-secrets.sh
```

**Entire history (comprehensive):**

```bash
check=whole-history ./scripts/githooks/scan-secrets.sh
```

## Removing sensitive data

Here are some tools that can help in removing sensitive data, such as passwords or API keys, from the Git history

- [`rtyley/bfg-repo-cleaner`](https://github.com/rtyley/bfg-repo-cleaner)
- [`newren/git-filter-repo`](https://github.com/newren/git-filter-repo)

For additional guidance, please refer also to the official [GitHub documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository).
