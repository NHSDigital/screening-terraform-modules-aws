---
name: "pre-commit-hooks"
description: "Comprehensive guide to screening-terraform-modules-aws pre-commit hooks. Documents all 26 hooks: what they check, how to fix failures, manual execution, and bypass scenarios. Essential for day-to-day development."
---

# Pre-Commit Hooks Skill

## Overview

Pre-commit hooks are **mandatory quality gates** that run automatically before every commit. This repository enforces 26 hooks across six categories:

1. **Terraform Tools** — formatting, validate, tflint, docs, provider locking
2. **General File Hygiene** — large files, merge conflicts, credentials, line endings
3. **Shell Scripts** — shellcheck linting
4. **File Formatting** — Terraform, Markdown, general format
5. **Security** — secret scanning, credentials, private keys
6. **Commit Messages** — conventional commit format validation

## Setup & Installation

### Prerequisites

Install tools via `mise` or `brew`:

```bash
mise install
# or manually:
brew install terraform tflint terraform-docs vale shellcheck
```

### Install Hooks

```bash
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

### Verify Installation

```bash
pre-commit run --all-files
```

If successful, output ends with:

```text
====== Summary =====
Passed: X, Failed: 0, Skipped: Y
```

---

## Hook Categories & Reference

### Category 1: Terraform Tools

These hooks operate on Terraform files (`.tf`, `.tfvars`).

#### 1.1 `terraform_fmt` — Format Terraform Code

**What it does:** Enforces consistent Terraform formatting (indentation, spacing, alignment).

**When it fails:**

- Inconsistent indentation
- Misaligned `=` signs
- Mixed spacing in blocks

**Fix:**

```bash
# Auto-fix via pre-commit
pre-commit run terraform_fmt --all-files

# Or manually
terraform fmt -recursive infrastructure/modules/
```

**Manual run:**

```bash
pre-commit run terraform_fmt --files infrastructure/modules/vpc/main.tf
```

---

#### 1.2 `terraform_validate` — Validate Terraform Configuration

**What it does:** Ensures Terraform syntax is valid and modules are properly configured.

Local pre-commit runs allow Terraform to refresh `.terraform.lock.hcl` when provider constraints change. In CI, `terraform_validate` is run with `terraform init -lockfile=readonly` so checks remain deterministic and do not mutate lockfiles.

**When it fails:**

- Invalid HCL syntax
- Missing required variables
- Invalid provider configuration
- Reference errors in locals/outputs

**Example failure:**

```text
Error: Invalid resource type

  on infrastructure/modules/s3-bucket/main.tf line 5, in resource "aws_s3_bucket_typo":
   5: resource "aws_s3_bucket_typo" "bucket" {

An invalid resource type "aws_s3_bucket_typo" has been used.
```

**Fix:**

1. Review the error message
2. Correct the HCL syntax or configuration
3. Run validation again:

   ```bash
   terraform -chdir="infrastructure/modules/s3-bucket" validate
   ```

**Manual run:**

```bash
pre-commit run terraform_validate --all-files
```

**Context:** Hook runs with `--env-vars=AWS_DEFAULT_REGION=eu-west-2` for consistency. If validation fails locally but passes in CI, check your `~/.aws/` configuration.

---

#### 1.3 `terraform_tflint` — Lint Terraform with tflint

**What it does:** Runs static analysis on Terraform code using rules defined in `scripts/config/.tflint.hcl`.

**When it fails:**

- Unused variables
- Literal values that should be variables
- Missing resource tags
- Non-standard naming
- Security issues

**Example failure:**

```text
1 issue(s) found:

Error: aws_s3_bucket does not have a "tags" argument (aws_resource_missing_tags)

  on infrastructure/modules/s3-bucket/main.tf:10, in resource "aws_s3_bucket":
  10: resource "aws_s3_bucket" "bucket" {
```

**Fix:**

1. Review the tflint rule and error message
2. Update the code to comply
3. If the rule is a false positive, update `.tflint.hcl`:

   ```bash
   code scripts/config/.tflint.hcl
   ```

**Manual run:**

```bash
pre-commit run terraform_tflint --all-files
```

**Check enabled rules:**

```bash
tflint --init  # Generate default config
tflint --format json  # Show detailed output
```

---

#### 1.4 `terraform_docs` — Generate Terraform Documentation

**What it does:** Auto-generates module README.md from variables, outputs, and code comments using `terraform-docs`.

**When it fails:**

- README.md is out of sync with variables/outputs
- Missing variable descriptions
- Invalid YAML metadata block in README

**Fix:**

```bash
# Auto-regenerate (or pre-commit will do this)
pre-commit run terraform_docs --all-files

# Verify
git diff infrastructure/modules/*/README.md
```

**Manual run:**

```bash
cd infrastructure/modules/s3-bucket/
terraform-docs markdown . > README.md
```

**Note:** Hook uses custom markers:

```markdown
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
```

Never manually edit the section between these markers; regenerate instead.

---

#### 1.5 `terraform_providers_lock` — Lock Providers for Cross-Platform Use

**What it does:** Ensures `.terraform.lock.hcl` includes provider versions for all target platforms:

- `linux_amd64` and `linux_arm64` (CI/CD)
- `darwin_amd64` and `darwin_arm64` (macOS)
- `windows_amd64` (Windows)

**When it fails:**

- `.terraform.lock.hcl` missing for one or more platforms
- Provider version mismatch across platforms

**Fix:**

```bash
# Regenerate locks
terraform -chdir="infrastructure/modules/s3-bucket" providers lock \
  -platform=linux_amd64 \
  -platform=linux_arm64 \
  -platform=darwin_amd64 \
  -platform=darwin_arm64 \
  -platform=windows_amd64
```

Or use the helper script:

```bash
./scripts/terraform/upgrade-module.sh infrastructure/modules/s3-bucket
```

**Manual run:**

```bash
pre-commit run terraform_providers_lock --all-files
```

---

### Category 2: General File Hygiene

#### 2.1 `check-added-large-files` — Prevent Large Files

**What it does:** Prevents committing files larger than 5 MB (prevents repository bloat).

**When it fails:**

```text
File is 10 MB, over limit of 5 MB
```

**Fix:**

1. Remove the file from git
2. Add to `.gitignore`
3. Use git-lfs if necessary

---

#### 2.2 `check-merge-conflict` — Detect Merge Markers

**What it does:** Prevents committing unresolved merge conflicts (lines with `<<<<<<<`, `=======`, `>>>>>>>`).

**Fix:** Resolve the merge conflict and remove the markers.

---

#### 2.3 `check-vcs-permalinks` — Validate VCS Permalinks

**What it does:** Ensures any GitHub links use commit SHAs, not branches (prevents link rot).

**Fix:** Replace branch-based links with commit-based links in comments/docs.

---

#### 2.4 `forbid-new-submodules` — Prevent Adding Submodules

**What it does:** Prevents adding git submodules (to keep the repository self-contained).

**Fix:** If you need to include external code, vendor it or use Terraform's built-in module sourcing.

---

#### 2.5 `no-commit-to-branch` — Prevent Direct Commits to Main

**What it does:** Prevents committing directly to `main` or `develop` (enforces PR workflow).

**When it fails:**

```text
You are attempting to commit to the branch: main
```

**Fix:** Create a feature branch:

```bash
git checkout -b feature/BCSS-12345-description
```

---

#### 2.6 `end-of-file-fixer` — Fix Missing Newlines

**What it does:** Auto-adds newline at end of files (POSIX standard).

**Result:** File is auto-fixed; re-stage it.

---

#### 2.7 `trailing-whitespace` — Remove Trailing Spaces

**What it does:** Auto-removes trailing whitespace from lines.

**Result:** File is auto-fixed; re-stage it.

---

#### 2.8 `check-yaml` — Validate YAML Syntax

**What it does:** Ensures YAML files (`.yml`, `.yaml`) are syntactically valid.

**When it fails:**

```text
Parse error at line 5, column 3: inconsistent indentation
```

**Fix:** Check indentation; YAML uses 2 or 4 spaces consistently.

---

#### 2.9 `check-executables-have-shebangs` — Ensure Shell Scripts Have Shebangs

**What it does:** Ensures all executable files start with a shebang (`#!/usr/bin/env bash`).

**Fix:**

```bash
# Add shebang to the top of the file
echo '#!/usr/bin/env bash' | cat - scripts/my-script.sh > temp && mv temp scripts/my-script.sh
chmod +x scripts/my-script.sh
```

---

#### 2.10 `check-case-conflict` — Detect Case Conflicts

**What it does:** Prevents files that differ only in case (problematic on case-insensitive filesystems like macOS/Windows).

**Fix:** Rename one of the conflicting files.

---

#### 2.11 `mixed-line-ending` — Fix Mixed Line Endings

**What it does:** Auto-converts mixed line endings to LF (Unix standard).

**Result:** File is auto-fixed; re-stage it.

---

#### 2.12 `detect-aws-credentials` — Detect Embedded AWS Credentials

**What it does:** Detects embedded AWS access keys, secret keys, session tokens.

**When it fails:**

```text
AWS credentials detected
```

**Fix:** Never commit credentials. Use:

- GitHub Secrets for CI/CD
- AWS assume role or iam OIDC federation
- `~/.aws/credentials` for local development

---

#### 2.13 `detect-private-key` — Detect Private Keys

**What it does:** Detects private key files (`.pem`, `.key`, `id_rsa`, etc.).

**Fix:** Remove the file and add to `.gitignore`.

---

### Category 3: Shell Script Linting

#### 3.1 `shellcheck` — Lint Shell Scripts

**What it does:** Runs `shellcheck` on all Bash/shell scripts to detect errors and bad practices.

**When it fails:**

```text
SC2119: Use foo "$@" if function's $1 should be reached.
```

**Common issues:**

- Unquoted variables: `$var` → `"$var"`
- Unused variables
- Unreachable code
- Common pitfalls

**Fix:**

1. Review the shellcheck warning
2. Update the script to comply
3. If it's a false positive, add `# shellcheck disable=SC2119` above the line

**Manual run:**

```bash
shellcheck scripts/terraform/upgrade-module.sh

# Show all rules
shellcheck -x -P SCRIPTDIR='$PWD' -S warning scripts/**/*.sh
```

**Reference:** [shellcheck Wiki](https://www.shellcheck.net/wiki/)

---

### Category 4: File Formatting

#### 4.1 `check-file-format` — General File Formatting

**What it does:** Runs custom checks via `scripts/githooks/check-file-format.sh` (EditorConfig compliance, etc.).

**When it fails:** Review the specific error message; fixes are usually auto-applied.

---

#### 4.2 `check-markdown-format` — Markdown Formatting

**What it does:** Runs custom checks via `scripts/githooks/check-markdown-format.sh` (Markdown linter, etc.).

**Common issues:**

- Incorrect heading levels
- Missing blank lines around code blocks
- Inconsistent list formatting

**Fix:**

```bash
pre-commit run check-markdown-format --all-files
```

---

#### 4.3 `check-english-usage` — English Prose & Grammar (Vale)

**What it does:** Checks documentation against English style rules using Vale (British English, NHS terminology).

**When it fails:**

```text
README.md:10:5: [Vale.Terms] Use 'repo-wide' instead of 'repo-wide mode'
README.md:15:12: [Vale.Spelling] Did you mean 'Boolean'?
```

**Common issues:**

- American vs British spelling (e.g., "color" → "colour")
- Terminology (e.g., "true/false" terminology)
- Missing articles or unclear phrasing

**Fix:**

1. Update the text to match the suggestion
2. Or add to `.vale.ini` if the suggestion is wrong for your context

**Manual run:**

```bash
vale README.md infrastructure/AGENTS.md
```

---

#### 4.4 `check-terraform-format` — Double-Check Terraform Format

**What it does:** Verifies Terraform code is formatted correctly via `scripts/githooks/check-terraform-format.sh`.

**Fix:** Same as `terraform_fmt` (auto-fixed).

---

### Category 5: Security & Secrets

#### 5.1 `scan-secrets` — Secret Scanning via Gitleaks

**What it does:** Scans entire git history for embedded secrets (API keys, credentials, etc.) using Gitleaks.

**When it fails:**

```text
Leaks found: 1
File: .env.example
Secret: aws_secret_access_key = "AKIA2EXAMPLE..."
```

**Common false positives:**

- Example/placeholder credentials in `.env.example`
- Test data that looks like credentials
- Version strings mistaken for IPv4 addresses

**Fix:**

#### Option 1: Real secret (CRITICAL)

```bash
# Remove the secret immediately
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch PATH_TO_FILE' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (warning: destructive)
git push origin +main
```

#### Option 2: False positive (Add to ignore list)

```bash
# Get the fingerprint from the error
# Add to .gitleaksignore
echo "commit-sha:path/to/file:rule-type:line-number" >> .gitleaksignore
```

**Manual run:**

```bash
gitleaks detect --verbose
gitleaks detect -i .gitleaksignore  # With ignores
```

---

### Category 6: Commit Messages

#### 6.1 `conventional-commit` — Validate Commit Message Format

**What it does:** Enforces conventional commit format: `<type>(<scope>): <description>`

**Format:**

```text
type(scope): description

optional body explaining the change

optional footer (e.g., Closes #123)
```

**Valid types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Examples:**

✅ **Good:**

```text
feat(s3-bucket): add encryption-at-rest configuration for NHS baseline compliance

Introduces optional KMS key support while defaulting to SSE-S3.
Existing modules fall back to service-managed encryption.

Closes #45
```

✅ **Also good:**

```text
fix(terraform-docs): regenerate docs for vpc module after provider upgrade
```

❌ **Bad:**

```text
Updated stuff
fix s3 bucket bug
add new feature
```

**When it fails:**

```text
Commit message does not conform to Conventional Commits.
Expected format: <type>(<scope>): <description>
Got: "update terraform"
```

**Fix:** Reword the commit message:

```bash
git commit --amend
```

**Manual validation:**

```bash
pre-commit run conventional-commit --all-files
# Or test a message:
echo "feat(vpc): add IPv6 support" | pre-commit run conventional-commit --input
```

**Reference:** [Conventional Commits](https://www.conventionalcommits.org/)

---

## Running Hooks Manually

### Run All Hooks on All Files

```bash
pre-commit run --all-files
```

### Run Specific Hook

```bash
pre-commit run terraform_fmt --all-files
pre-commit run shellcheck --files scripts/terraform/upgrade-module.sh
```

### Run on Staged Files Only (Normal)

```bash
pre-commit run
# or during commit (automatic)
git commit -m "..."
```

### Skip Pre-Commit Hooks (NOT RECOMMENDED)

```bash
git commit --no-verify -m "..."
```

⚠️ **Use only when:**

- Hooks have a genuine bug (report it immediately)
- Emergency production fix
- You'll fix the issues immediately in a follow-up commit

**NEVER use `--no-verify` to bypass security checks (Gitleaks, detect-aws-credentials).**

---

## Troubleshooting

### Hooks Installed but Not Running

```bash
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
git config --local core.hooksPath .git/hooks
```

### One Hook Always Fails

Run in isolation to debug:

```bash
bash -x .git/hooks/pre-commit | grep -A5 <hook-id>
```

### Provider Lock File Conflicts

Delete and regenerate:

```bash
rm infrastructure/modules/*/.terraform.lock.hcl
pre-commit run terraform_providers_lock --all-files
```

### shellcheck Failing Locally but Not CI

Ensure same shellcheck version:

```bash
shellcheck --version  # Compare with CI logs
```

### Terraform Validate Fails Only Locally

Check AWS credentials and region:

```bash
echo $AWS_DEFAULT_REGION
aws sts get-caller-identity
```

### Vale/English Checks Too Strict

Edit `.vale.ini` to relax rules or add exceptions for your terminology.

---

## Quick Reference Table

| Hook | Files | Auto-Fix | Severity | Category |
| --- | --- | --- | --- | --- |
| `terraform_fmt` | `.tf`, `.tfvars` | ✅ Yes | Medium | Terraform |
| `terraform_validate` | `.tf`, `.tfvars` | ❌ No | High | Terraform |
| `terraform_tflint` | `.tf`, `.tfvars` | ❌ No | Medium | Terraform |
| `terraform_docs` | `.tf`, README.md | ✅ Yes | Medium | Terraform |
| `terraform_providers_lock` | `.terraform.lock.hcl` | ✅ Yes | High | Terraform |
| `shellcheck` | `.sh` | ❌ No | Medium | Shell |
| `check-file-format` | All | Varies | Low | Format |
| `check-markdown-format` | `.md` | Varies | Low | Format |
| `check-english-usage` | `.md` | ❌ No | Low | Format |
| `detect-aws-credentials` | All | ❌ No | **CRITICAL** | Security |
| `detect-private-key` | All | ❌ No | **CRITICAL** | Security |
| `scan-secrets` | All | ❌ No | **CRITICAL** | Security |
| `conventional-commit` | Commit msg | ❌ No | Medium | Commit |
| `no-commit-to-branch` | N/A | ❌ No | High | Git |

---

## Best Practices

1. **Never bypass security checks** — Gitleaks, credentials, and private key detection catch real leaks
2. **Fix formatting immediately** — auto-fixed hooks should be re-staged and committed
3. **Run before pushing** — all hooks must pass before a PR is created
4. **Keep hooks updated** — pre-commit regularly updates hook repositories
5. **Document exceptions** — if you add a `# shellcheck disable=...`, explain why
6. **Review hook output carefully** — some "errors" are style preferences; others are real bugs

---

## References

- [pre-commit framework](https://pre-commit.com/)
- [antonbabenko/pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
- [shellcheck](https://www.shellcheck.net/)
- [terraform-docs](https://terraform-docs.io/)
- [Vale](https://vale.sh/)
- [Gitleaks](https://github.com/gitleaks/gitleaks)
- [Conventional Commits](https://www.conventionalcommits.org/)
