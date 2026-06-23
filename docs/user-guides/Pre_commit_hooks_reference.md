# Pre-Commit Hooks Reference Guide

This is the comprehensive reference for all pre-commit hooks in the `screening-terraform-modules-aws` repository. For quick setup, see [Run Git hooks on commit](Run_Git_hooks_on_commit.md).

## Table of Contents

- [Quick Setup](#quick-setup)
- [What Are Pre-Commit Hooks?](#what-are-pre-commit-hooks)
- [Hook Categories](#hook-categories)
  - [Terraform Tools](#terraform-tools)
  - [Configuration Hooks](#configuration-hooks)
  - [File Hygiene](#file-hygiene)
  - [Shell Scripts](#shell-scripts)
  - [File Formatting](#file-formatting)
  - [Security & Secrets](#security--secrets)
  - [Commit Messages](#commit-messages)
- [Quick Fix Reference](#quick-fix-reference)
- [Common Issues & Troubleshooting](#common-issues--troubleshooting)
- [Running Hooks Manually](#running-hooks-manually)
- [When to Skip Hooks (Emergency Only)](#when-to-skip-hooks-emergency-only)
- [References](#references)

---

## Quick Setup

```bash
# Install hooks (run once after cloning)
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg

# Run all hooks on the entire repository
pre-commit run --all-files

# On next commit, hooks run automatically
git commit -m "feat(module): description"
```

---

## What Are Pre-Commit Hooks?

Pre-commit hooks are **automated quality checks** that run before every commit. They ensure code meets the repository's standards for formatting, security, and testing.

**Benefits:**

- Catch errors locally before pushing to GitHub
- Enforce consistent code style and security
- Prevent secrets from being committed
- Save CI/CD time by fixing issues early

**This repository has 27 hooks** covering Terraform, shell scripts, file formatting, security scanning, and commit message validation.

---

## Hook Categories

### Terraform Tools

These hooks operate on `.tf` and `.tfvars` files to ensure Terraform modules are well-formatted, validated, and documented.

#### `terraform_fmt` — Format Code

**What it does:** Enforces consistent Terraform formatting (indentation, spacing, alignment).

**When it fails:**

```text
✗ Failed
Terraform formatting checks failed
```

**Fix:**

```bash
# Auto-fix
terraform fmt -recursive infrastructure/modules/
# or
pre-commit run terraform_fmt --all-files

# Then re-stage and commit
git add .
git commit -m "..."
```

**Manual run:**

```bash
pre-commit run terraform_fmt --files infrastructure/modules/vpc/main.tf
```

---

#### `terraform_validate` — Validate Configuration

**What it does:** Checks that Terraform syntax is valid and modules are properly configured.

In this repository's pre-commit configuration, `terraform_providers_lock` runs before `terraform_validate` so lock file platform coverage is reconciled first.

Local pre-commit runs allow Terraform to refresh `.terraform.lock.hcl` when provider constraints change. In CI, `terraform_validate` runs with `terraform init -lockfile=readonly` so checks stay deterministic and do not mutate lock files.

**When it fails:**

```text
Error: Invalid resource type

  on infrastructure/modules/s3-bucket/main.tf line 5, in resource "aws_s3_bucket_typo":
   5: resource "aws_s3_bucket_typo" "bucket" {

An invalid resource type "aws_s3_bucket_typo" has been used.
```

**Fix:**

1. Review the error message
2. Correct the HCL syntax (typos, missing brackets, invalid references, etc.)
3. Verify locally:

   ```bash
   terraform -chdir="infrastructure/modules/s3-bucket" validate
   ```

**Common causes:**

- Resource type typos: `aws_s3_bucket_typo` instead of `aws_s3_bucket`
- Missing required variables
- Invalid provider configuration or missing provider blocks
- Circular dependencies in locals/outputs

---

#### `terraform_tflint` — Static Analysis

**What it does:** Runs `tflint` to detect code issues, bad practices, and security concerns using rules defined in `scripts/config/.tflint.hcl`.

**When it fails:**

```text
Error: aws_s3_bucket does not have a "tags" argument (aws_resource_missing_tags)
```

**Fix:**

1. Review the tflint rule and message
2. Update your code to comply
3. If it's a legitimate exception, add a tflint disable comment:

   ```hcl
   resource "aws_s3_bucket" "test" {
     # tflint-ignore=aws_resource_missing_tags
     bucket = "my-test-bucket"
   }
   ```

**Common issues:**

- Missing resource tags
- Unused variables or outputs
- Literal values that should be variables
- Non-standard naming conventions
- Potential security issues (e.g., public access not blocked)

---

#### `terraform_docs` — Generate Documentation

**What it does:** Auto-generates the module README.md from variables, outputs, and code comments.

**When it fails:**

```text
✗ Failed
Documentation is out of sync
```

**Fix:**

```bash
# Auto-regenerate documentation
pre-commit run terraform_docs --all-files

# Verify the changes
git diff infrastructure/modules/*/README.md

# Re-stage and commit
git add .
git commit -m "..."
```

**Important:** Never manually edit the section between these markers:

```markdown
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
```

Always regenerate instead using the hook or:

```bash
cd infrastructure/modules/s3-bucket/
terraform-docs markdown . > README.md
```

---

#### `terraform_providers_lock` — Cross-Platform Provider Locking

**What it does:** Ensures `.terraform.lock.hcl` includes provider versions for all target platforms:

- `linux_amd64`, `linux_arm64` (CI/CD)
- `darwin_amd64`, `darwin_arm64` (macOS)
- `windows_amd64` (Windows)

**When it fails:**

```text
✗ Failed
Lock file is not cross-platform
Missing platform: darwin_amd64
```

**Fix:**

Option 1: Use the upgrade helper (recommended)

```bash
./scripts/terraform/upgrade-module.sh infrastructure/modules/s3-bucket
```

Option 2: Manual regeneration

```bash
terraform -chdir="infrastructure/modules/s3-bucket" providers lock \
  -platform=linux_amd64 \
  -platform=linux_arm64 \
  -platform=darwin_amd64 \
  -platform=darwin_arm64 \
  -platform=windows_amd64
```

**Why this matters:** Ensures all developers (macOS, Linux, Windows) and CI/CD systems get consistent provider versions.

---

### Configuration Hooks

These hooks maintain critical configuration files and ensure they stay in sync with repository state.

#### `regenerate-dependabot-config` — Update Dependabot Configuration

**What it does:** Automatically regenerates `.github/dependabot.yaml` by scanning `infrastructure/modules/` for all modules with `versions.tf` files. This ensures Dependabot watches every Terraform module without manual maintenance.

**When it fails:**

```text
✗ Failed
⚠ Dependabot configuration is out of date
  Regenerating: .github/dependabot.yaml

Please review the updated configuration and commit it:
  git add .github/dependabot.yaml
  git commit -m 'chore: update Dependabot configuration'
```

**What triggers it:**

- Adding a new module with `infrastructure/modules/<module-name>/versions.tf`
- Removing or renaming a module
- Any change to module `versions.tf` files

**Fix:**

The hook regenerates the file automatically. Simply review and commit it:

```bash
# Review the changes
git diff .github/dependabot.yaml

# Commit the regenerated configuration
git add .github/dependabot.yaml
git commit -m "chore: update Dependabot configuration"
```

**What gets generated:**

- All non-Terraform ecosystems preserved (Docker, GitHub Actions, npm, pip)
- One entry per module in `infrastructure/modules/`
- Daily update schedule for all ecosystems
- Nested modules supported (e.g., `infrastructure/modules/vpc/` counts as one entry)
- `.terraform/` cache directories excluded automatically

**Example output:**

```yaml
version: 2

updates:
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "daily"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"

  - package-ecosystem: "terraform"
    directory: "infrastructure/modules/s3-bucket"
    schedule:
      interval: "daily"

  - package-ecosystem: "terraform"
    directory: "infrastructure/modules/kms"
    schedule:
      interval: "daily"
  # ... (one entry per module)
```

**Troubleshooting:**

If the hook is skipped or fails silently, run manually:

```bash
bash scripts/generate-dependabot-config.sh .github/dependabot.yaml
```

To verify the configuration is valid:

```bash
# Install yq if needed: mise install yq
yq eval '.' .github/dependabot.yaml
```

---

### File Hygiene

These hooks catch common Git mistakes and enforce best practices.

#### `check-added-large-files`

**What it does:** Prevents committing files larger than 5 MB (prevents repository bloat).

**Fix:** Remove the file and add to `.gitignore`, or use Git LFS for binary files.

---

#### `check-merge-conflict`

**What it does:** Detects unresolved merge conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).

**Fix:** Resolve the merge conflict and remove the markers, then commit.

---

#### `no-commit-to-branch`

**What it does:** Prevents committing directly to `main` (enforces PR workflow).

**When it fails:**

```text
You are attempting to commit to the branch: main
```

**Fix:** Create a feature branch:

```bash
git checkout -b feature/BCSS-12345-description
```

---

#### `end-of-file-fixer` & `trailing-whitespace`

**What they do:** Auto-fix missing newlines at end of files and remove trailing spaces.

**Result:** Files are auto-fixed; re-stage and commit:

```bash
git add .
git commit -m "..."
```

---

#### `check-yaml`

**What it does:** Validates YAML syntax in `.yml` and `.yaml` files.

**When it fails:**

```text
Parse error at line 5, column 3: inconsistent indentation
```

**Fix:** Check indentation; YAML uses 2 or 4 spaces consistently, not tabs.

---

### Shell Scripts

#### `shellcheck` — Shell Script Linting

**What it does:** Validates Bash/shell scripts for errors and bad practices.

**When it fails:**

```text
SC2119: Use foo "$@" if function's $1 should be reached.
```

**Fix:**

1. Review the warning code
2. Update the script to comply
3. If it's a false positive, add a disable comment:

   ```bash
   # shellcheck disable=SC2119
   my_function() {
     echo $1
   }
   ```

**Common issues:**

- Unquoted variables: `$var` → `"$var"`
- Unused variables
- Unreachable code
- Literal values that should be parameters

**Manual run:**

```bash
shellcheck scripts/terraform/upgrade-module.sh
```

**Reference:** [shellcheck Wiki](https://www.shellcheck.net/wiki/)

---

### File Formatting

#### `check-file-format`

**What it does:** Validates general file formatting (EditorConfig compliance, etc.).

**Fix:** Review error message; fixes usually auto-apply. Re-stage if needed.

---

#### `check-markdown-format`

**What it does:** Validates Markdown syntax and style (via Markdown linter).

**Common issues:**

- Incorrect heading levels
- Missing blank lines around code blocks
- Inconsistent list formatting

**Fix:**

```bash
pre-commit run check-markdown-format --all-files
```

---

#### `check-english-usage` — English & Terminology (Vale)

**What it does:** Checks documentation against British English style rules using Vale.

**When it fails:**

```text
README.md:10:5: [Vale.Terms] Use 'repo-wide' instead of 'repo-wide mode'
README.md:15:12: [Vale.Spelling] Did you mean 'Boolean'?
```

**Common issues:**

- American vs. British spelling: "color" → "colour"
- Terminology: true/false wording
- Missing articles or unclear phrasing

**Fix:**

```bash
# Update the text to match the suggestion, or
# Relax/customize rules in .vale.ini if needed
code README.md
```

**Manual run:**

```bash
vale README.md
```

---

### Security & Secrets

⚠️ **CRITICAL: These hooks are non-negotiable. Never skip them.**

#### `detect-aws-credentials`

**What it does:** Detects embedded AWS access keys, secret keys, and session tokens.

**When it fails:**

```text
AWS credentials detected
```

**Fix:**

1. **Remove the credential immediately**
2. Use GitHub Secrets for CI/CD.
3. Use AWS IAM assume role or OIDC federation.
4. Use `~/.aws/credentials` for local development (never commit).

**Prevention:** Never paste real credentials anywhere.

---

#### `detect-private-key`

**What it does:** Detects private key files (`.pem`, `.key`, `id_rsa`, etc.).

**Fix:** Remove the file and add to `.gitignore`.

---

#### `scan-secrets-staged-changes` — Gitleaks (staged files only)

**What it does:** Scans only the staged changes for embedded secrets (API keys, credentials, etc.).

**When to use:** During pre-commit (automatically runs on `git commit`). Catches secrets before they're committed.

**When it fails:**

```text
Leaks found: 1
File: .env
Secret: aws_secret_access_key = "AKIA..."
```

**Fix:**

If it's a **real secret** (CRITICAL):

```bash
# Unstage the file
git reset .env

# Remove from working directory (or edit to remove the secret)
rm .env  # or edit to remove secrets

# Stage and commit the corrected version
git add .env
git commit -m "fix: remove secrets"
```

If it's a **false positive** (e.g., example credentials):

```bash
# Add to .gitleaksignore
echo "commit-sha:path/to/file:rule-type:line-number" >> .gitleaksignore

# Re-stage and commit
git add .gitleaksignore
git commit -m "chore: ignore false positive secret scan"
```

---

#### `scan-secrets-whole-history` — Gitleaks (complete history)

**What it does:** Scans entire git history for embedded secrets (API keys, credentials, etc.). Runs on `pre-commit run --all-files` or in CI/CD.

**When to use:** Full repository scans (CI/CD, local validation, before pushing to remote).

**When it fails:**

```text
Leaks found: 1
File: config/old-backup.tf
Secret: aws_access_key_id = "AKIAIOSFODNN7EXAMPLE"
Commit: abc1234
```

**Fix:**

If it's a **real secret** (CRITICAL — secret is in history):

```bash
# Use git filter-branch to remove from history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch config/old-backup.tf' \
  --prune-empty --tag-name-filter cat -- --all

# Force push to remove from remote
git push origin +main

# Regenerate any AWS/API credentials that were exposed
```

If it's a **false positive** (e.g., example credentials):

```bash
# Add to .gitleaksignore
echo "commit-sha:path/to/file:rule-type:line-number" >> .gitleaksignore

# Re-run to verify
pre-commit run scan-secrets-whole-history --all-files
```

**Manual runs:**

```bash
# Scan staged changes only
check=staged-changes ./scripts/githooks/scan-secrets.sh

# Scan entire history
check=whole-history ./scripts/githooks/scan-secrets.sh
```

---

### Commit Messages

#### `conventional-commit` — Message Format

**What it does:** Validates that commit messages follow Conventional Commits format.

**Format:**

```text
<type>(<scope>): <description>

optional body explaining the change

optional footer (e.g., Closes #123)
```

**Valid types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Examples:**

✅ **Good:**

```text
feat(s3-bucket): add encryption-at-rest configuration

Introduces optional KMS key support while defaulting to SSE-S3.
Existing modules fall back to service-managed encryption.

Closes #45
```

✅ **Also good:**

```text
fix(vpc): correct CIDR block validation logic
```

❌ **Bad:**

```text
Updated stuff
fix s3 bucket
add new feature
```

**When it fails:**

```text
Commit message does not conform to Conventional Commits.
Expected format: <type>(<scope>): <description>
```

**Fix:**

```bash
git commit --amend
# Edit the message to follow the format
```

**Reference:** [Conventional Commits](https://www.conventionalcommits.org/)

---

## Quick Fix Reference

| Problem | Command |
| --- | --- |
| Terraform formatting | `terraform fmt -recursive infrastructure/modules/` |
| Module docs out of sync | `pre-commit run terraform_docs --all-files` |
| Provider locks missing platforms | `./scripts/terraform/upgrade-module.sh infrastructure/modules/<name>` |
| Dependabot config out of date | Commit the regenerated `.github/dependabot.yaml` |
| Shell script errors | Fix the issue; re-run `pre-commit run shellcheck` |
| Trailing whitespace | `pre-commit run --all-files` (auto-fixed) |
| Commit message format | `git commit --amend` and reword the message |
| English/spelling | Update the text or adjust `.vale.ini` |
| Merge conflict markers | Resolve the conflict and remove markers |

---

## Common Issues & Troubleshooting

### Hooks Not Running

```bash
# Verify installation
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg

# Check hooks are installed
cat .git/hooks/pre-commit
cat .git/hooks/commit-msg
```

### One Hook Always Fails

Run in isolation:

```bash
pre-commit run <hook-id> --all-files
```

Then check the `.pre-commit-config.yaml` for that hook's configuration.

### Provider Lock File Conflicts

```bash
# Delete locks
rm infrastructure/modules/*/.terraform.lock.hcl

# Regenerate
pre-commit run terraform_providers_lock --all-files
```

### shellcheck Failing Locally but Not CI

Ensure same shellcheck version:

```bash
shellcheck --version
```

Compare with CI logs and update locally if needed.

### Terraform Validate Fails Only Locally

Check AWS credentials and region:

```bash
echo $AWS_DEFAULT_REGION
aws sts get-caller-identity
```

If `AWS_DEFAULT_REGION` is missing, add it:

```bash
export AWS_DEFAULT_REGION=eu-west-2
pre-commit run terraform_validate --all-files
```

### Vale Checks Too Strict

Edit `.vale.ini` to relax rules or add custom exceptions for your terminology:

```bash
code .vale.ini
```

---

## Running Hooks Manually

### All Hooks on Full Repository

```bash
pre-commit run --all-files
```

### Specific Hook

```bash
pre-commit run terraform_fmt --all-files
pre-commit run shellcheck --files scripts/terraform/upgrade-module.sh
```

### On Staged Files Only (Default)

```bash
pre-commit run
# Hooks run automatically on next commit
```

---

## When to Skip Hooks (Emergency Only)

```bash
git commit --no-verify -m "..."
```

⚠️ **Use only when:**

- A hook has a genuine bug (report it immediately)
- Emergency production fix
- You'll fix the issues immediately in a follow-up commit

**NEVER use `--no-verify` to bypass:**

- `detect-aws-credentials` — detects leaked credentials
- `detect-private-key` — detects leaked private keys
- `scan-secrets-staged-changes` — scans staged changes for secrets
- `scan-secrets-whole-history` — scans entire git history for secrets

If you use `--no-verify`, report the issue immediately.

---

## References

- [pre-commit framework](https://pre-commit.com/)
- [antonbabenko/pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
- [shellcheck](https://www.shellcheck.net/)
- [terraform-docs](https://terraform-docs.io/)
- [Vale — English Prose Linter](https://vale.sh/)
- [Gitleaks — Secret Scanning](https://github.com/gitleaks/gitleaks)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**For detailed AI agent guidance**, see [`.github/skills/pre-commit-hooks.skill.md`](../../.github/skills/pre-commit-hooks.skill.md).
