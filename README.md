# Screening Terraform Modules (AWS)

Canonical source of reusable, opinionated Terraform modules for the NHS Screening programme on AWS. Modules are consumed by downstream repositories (primarily [`NHSDigital/bcss`](https://github.com/NHSDigital/bcss)) via Git source with pinned release tags.

## Table of Contents

- [Screening Terraform Modules (AWS)](#screening-terraform-modules-aws)
  - [Table of Contents](#table-of-contents)
  - [Setup](#setup)
    - [Prerequisites](#prerequisites)
    - [Tool Version Source of Truth](#tool-version-source-of-truth)
    - [Configuration](#configuration)
  - [Usage](#usage)
    - [Consuming a module](#consuming-a-module)
    - [Testing](#testing)
  - [Design](#design)
    - [Repository structure](#repository-structure)
    - [Module layout](#module-layout)
    - [Wrapper module pattern](#wrapper-module-pattern)
    - [Context and tagging](#context-and-tagging)
  - [Available modules](#available-modules)
  - [Pre-commit hooks](#pre-commit-hooks)
    - [Local setup](#local-setup)
    - [Hooks included](#hooks-included)
    - [Conventional commits](#conventional-commits)
  - [Contributing](#contributing)
  - [Contacts](#contacts)
  - [Licence](#licence)

## Setup

Clone the repository and install tooling:

```shell
git clone https://github.com/NHSDigital/screening-terraform-modules-aws.git
cd screening-terraform-modules-aws
```

### Prerequisites

Tool versions are managed via [mise](https://mise.jdx.dev/). See `.tool-versions` for the pinned versions (and `mise.toml` for the TOML configuration). The key dependencies are:

| Tool | Version | Purpose |
| --- | --- | --- |
| [Terraform](https://www.terraform.io/) | >= 1.13.2 | Infrastructure as code |
| [tflint](https://github.com/terraform-linters/tflint) | 0.59.1 | Terraform linter |
| [terraform-docs](https://terraform-docs.io/) | 0.24.0 | Auto-generate module documentation |
| [terraform-config-inspect](https://github.com/hashicorp/terraform-config-inspect) | latest | Generate aliased providers for validation |
| [pre-commit](https://pre-commit.com/) | 4.6.0 | Git hook framework |
| [Vale](https://vale.sh/) | 3.6.0 | English prose linter |
| [Gitleaks](https://github.com/gitleaks/gitleaks) | 8.30.1 | Secret scanning |
| [jq](https://jqlang.github.io/jq/) | 1.7.1 | JSON processor |
| [shellcheck](https://www.shellcheck.net/) | — | Shell script linter |
| [GNU make](https://www.gnu.org/software/make/) | >= 3.82 | Task runner |

Install all tool versions:

```shell
mise install
```

### Tool Version Source of Truth

Tool versions are maintained in two complementary formats for compatibility:

- **`.tool-versions`** (asdf format) — Legacy format, used by CI/CD workflows and some tooling
- **`mise.toml`** (TOML format) — Modern mise configuration, with `mise.lock` for reproducible cross-platform builds

Both files must be kept in sync. Update `.tool-versions` first, then ensure `mise.toml` is updated accordingly. Run `mise lock` to regenerate the lock file.

For routine upgrades, use the shared helper so local and CI use the same logic:

```shell
bash scripts/mise/update-tool-versions.sh
```

Choose an upgrade level when needed:

```shell
# Patch updates only
bash scripts/mise/update-tool-versions.sh --upgrade-level patch

# Minor updates only
bash scripts/mise/update-tool-versions.sh --upgrade-level minor

# Major updates only
bash scripts/mise/update-tool-versions.sh --upgrade-level major

# All updates (default)
bash scripts/mise/update-tool-versions.sh --upgrade-level all
```

Preview only (no file changes):

```shell
bash scripts/mise/update-tool-versions.sh --dry-run
```

The scheduled `dependency-tools-mise-upgrade` workflow defaults to patch updates, and manual runs can override the level via the `upgrade_level` input.

Local development and CI both resolve pinned versions from these files through mise.

### Configuration

```shell
make config
```

This installs Git hooks, configures the local development environment, and prepares the toolchain.

### Validation Tests

This branch includes comprehensive test coverage for new features:

- **Conventional commit checks** — native bash-based validation script replacing an external dependency
- **Workflow security** — GitHub Actions and pre-commit hooks pinned to immutable commit SHAs
- **Tool version sync** — `.tool-versions` and `mise.toml` consistency checks

Run validation tests:

```shell
make test-validations                   # Run all validations
make test-commit-validator              # Test conventional commit checks
make test-workflow-pinning              # Test action/hook pinning
bash tests/run-all-tests.sh             # Run all tests directly
```

For more details, see [tests/README.md](tests/README.md).

## Usage

### Consuming a module

Reference a module from a downstream Terraform stack using a pinned Git ref:

```hcl
module "my_bucket" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/s3-bucket?ref=v3.0.0"

  context = module.this.context
  name    = "audit-data"
}
```

All modules accept a `context` input for naming and tagging. See [Context and tagging](#context-and-tagging) below.

### Testing

Validate modules locally:

```shell
# Format
terraform fmt -recursive infrastructure/modules/

# Validate a specific module
terraform -chdir=infrastructure/modules/s3-bucket init -backend=false
terraform -chdir=infrastructure/modules/s3-bucket validate

# Run all pre-commit checks
pre-commit run --all-files
```

### Refreshing provider locks and documentation

Use the upgrade helper to refresh a single module after dependency changes:

```shell
./scripts/terraform/upgrade-module.sh infrastructure/modules/vpc
```

To refresh every module in the repository, use:

```shell
./scripts/terraform/upgrade-module.sh update-all
```

repo-wide mode warns before it starts because it iterates every module under `infrastructure/modules`.

## Design

### Repository structure

```text
screening-terraform-modules-aws/
├── infrastructure/
│   └── modules/           # All reusable Terraform modules
│       ├── tags/          # Foundation module (naming + tagging context)
│       │   └── exports/
│       │       └── context.tf  # File copied into every other module
│       ├── s3-bucket/     # Exemplar: S3 wrapper
│       ├── iam/           # Exemplar: iam policies & roles
│       ├── secrets-manager/
│       ├── kms/
│       └── ...            # Additional modules
├── scripts/               # Helper scripts (linting, hooks, Docker)
├── docs/                  # ADRs, developer guides, diagrams
├── .pre-commit-config.yaml # Pre-commit hook definitions
├── scripts/githooks/generate-terraform-providers.sh # Aliased provider generation for validate
├── .tool-versions         # Tool versions (asdf format, legacy)
├── mise.toml              # Tool configuration (TOML format)
├── mise.lock              # Locked versions for reproducible builds
├── .github/
│   └── workflows/
│       ├── stage-1-pre-commit.yml        # Main CI quality gate
│       ├── cicd-1-pull-request.yaml      # PR checks
│       ├── stage-1-coding-standards.yaml # Legacy (kept for rollback)
│       └── stage-1-commit.yaml           # Legacy (kept for rollback)
├── tests/                 # Validation tests
│   ├── test-conventional-commit.sh       # Validator unit tests
│   ├── test-workflow-security.sh         # Action pinning verification
│   ├── run-all-tests.sh                  # Test runner
│   └── README.md                         # Testing documentation
├── Makefile
└── VERSION
```

### Module layout

Every module **must** contain the following files:

```text
infrastructure/modules/<module-name>/
├── main.tf          # Resource definitions with header comment block
├── variables.tf     # Inputs: types, descriptions, defaults, validation blocks
├── outputs.tf       # Outputs with descriptions and stable names
├── versions.tf      # required_version and provider constraints for the module
├── context.tf       # Copied from tags/exports/context.tf (never edited directly)
├── locals.tf        # Derived/computed values, naming logic
└── README.md        # Usage docs with enforcement table and examples
```

### Wrapper module pattern

Modules are thin, opinionated wrappers around community Terraform modules that enforce the NHS Screening security baseline:

```hcl
################################################################
# S3 bucket
#
# Enforces:
#   * Ownership: BucketOwnerEnforced
#   * Encryption: SSE enabled
#   * Transport: TLS-only
#   * Public access: blocked at all toggles
################################################################

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"

  create_bucket = module.this.enabled
  bucket        = module.this.id

  # Security baseline (fixed and enforced)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = module.this.tags
}
```

**Security baseline** — every module must enforce:

| Control | Requirement |
| --- | --- |
| Encryption at rest | KMS or service-managed; no unencrypted storage |
| Encryption in transit | TLS required where applicable |
| No public access | Blocked by default at all available toggles |
| iam least-privilege | No `*` actions in policies |
| Logging | Enabled where the service supports it |
| Tagging | All resources via `module.this.tags` |

### Context and tagging

Every module includes `context.tf` (copied from `infrastructure/modules/tags/exports/context.tf`). This instantiates `module "this"` which provides:

- `module.this.id` — generated resource name (e.g., `bcss-test-account-default-my-resource`)
- `module.this.tags` — standard tag map with all NHS-required labels
- `module.this.context` — full context object passable to child modules
- `module.this.enabled` — boolean creation gate

Rules:

1. **Never edit `context.tf` directly** — it is a copy from `tags/exports/context.tf`.
2. Use `source = "../tags"` (relative) within this repository.
3. Consumer stacks use the Git source with a pinned ref.

## Available modules

| Module | Wraps | Description |
| --- | --- | --- |
| `api-gateway` | — | API Gateway configuration |
| `aws-backup-destination` | — | AWS Backup destination vault |
| `aws-backup-source` | — | AWS Backup source configuration |
| `aws-scheduler` | — | EventBridge Scheduler |
| `cognito` | — | Cognito user/identity pools |
| `cw-firehose-splunk` | — | CloudWatch to Splunk via Firehose |
| `ecr` | — | ECR repository |
| `ecs-cluster` | — | ECS Fargate cluster |
| `elasticache` | — | ElastiCache cluster |
| `github-config` | — | GitHub OIDC and runner configuration |
| `guardduty` | — | GuardDuty threat detection |
| `iam` | `terraform-aws-modules/iam/aws` | iam policies and roles |
| `inspector` | — | Inspector vulnerability scanning |
| `kms` | `terraform-aws-modules/kms/aws` | KMS key with policy enforcement |
| `lambda` | — | Lambda function |
| `lambda-layer` | — | Lambda layer |
| `license-manager` | — | License Manager configuration |
| `parameter_store` | — | SSM Parameter Store |
| `r53-healthcheck` | — | Route 53 health checks |
| `rds-database` | — | RDS database (logical) |
| `rds-gateway-ecs-task` | — | RDS gateway ECS task definition |
| `rds-instance` | — | RDS instance |
| `rds-users` | — | RDS user management |
| `s3` | — | S3 (legacy) |
| `s3-bucket` | `terraform-aws-modules/s3-bucket/aws` | S3 bucket with full security |
| `secrets-manager` | `terraform-aws-modules/secrets-manager/aws` | Secrets Manager |
| `security-hub` | — | Security Hub |
| `sns` | Native resources | SNS topic with encryption |
| `sqs` | — | SQS queue |
| `tags` | — | Foundation: naming and tagging context |
| `vpc` | — | VPC |
| `vpce` | — | VPC endpoint (single) |
| `vpces` | — | VPC endpoints (multiple) |
| `waf` | — | WAF web ACL |

## Pre-commit hooks

This repository uses [pre-commit](https://pre-commit.com/) to run quality checks before code is committed locally, and in CI via the `stage-1-pre-commit.yml` GitHub Actions workflow.

The reusable workflows `stage-1-coding-standards.yaml` and `stage-1-commit.yaml` now call `stage-1-pre-commit.yml` for coding checks. Their legacy per-check jobs are kept disabled for fast rollback.

The PR workflow `cicd-1-pull-request.yaml` also includes:

- a non-blocking Conventional Commit advisory check for all commit messages in the PR
- a final `all-checks-complete` aggregation job suitable for branch protection

CI tooling versions are resolved from `.tool-versions` via mise. Both `.tool-versions` and `mise.toml` are maintained in sync.

For Terraform-related matrix shards, CI enables `TF_PLUGIN_CACHE_DIR` and caches `~/.terraform.d/plugin-cache` to reduce repeated provider downloads for hooks that initialise Terraform (for example `terraform_validate` and `terraform_tflint`).

### Local setup

```shell
# Install hooks (run once after cloning)
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg

# Run all hooks against the full repo
pre-commit run --all-files
```

### Hooks included

This repository enforces **26 hooks** across six categories:

| Category | Hooks | Purpose |
| --- | --- | --- |
| **Terraform** (5) | `terraform_fmt`, `terraform_providers_lock`, `terraform_validate`, `terraform_tflint`, `terraform_docs` | Format, lock, validate, lint, and document Terraform modules |
| **File Hygiene** (8) | `check-added-large-files`, `check-merge-conflict`, `no-commit-to-branch`, `end-of-file-fixer`, `trailing-whitespace`, `check-yaml`, `check-case-conflict`, `mixed-line-ending` | Prevent commits of large files, merge conflicts, direct commits to main, and enforce line ending consistency |
| **Shell Scripts** (1) | `shellcheck` | Lint Bash/shell scripts for errors and bad practices |
| **File Formatting** (4) | `check-file-format`, `check-markdown-format`, `check-english-usage`, `check-terraform-format` | Enforce consistent formatting and British English in documentation |
| **Security** (3) | `detect-aws-credentials`, `detect-private-key`, `scan-secrets` | **CRITICAL:** Prevent credentials and secrets from being committed |
| **Commit Messages** (1) | `conventional-commit` | Enforce conventional commit format |
| **Utilities** (4) | `generate-terraform-providers`, `check-executables-have-shebangs`, custom githooks | Support functions for Terraform validation and general checks |

### Understanding Hook Failures

**For a comprehensive reference** covering each hook, common failure scenarios, and how to fix them, see:

→ **[Pre-Commit Hooks Reference Guide](docs/user-guides/Pre_commit_hooks_reference.md)** — Detailed documentation with examples and troubleshooting

**Common quick fixes:**

| Issue | Fix |
| --- | --- |
| Terraform format mismatch | `terraform fmt -recursive infrastructure/modules/` |
| Module docs out of sync | `pre-commit run terraform_docs --all-files` |
| Shell script errors | Review and fix; re-run `pre-commit run shellcheck` |
| English/spelling | Update text per Vale rules or adjust `.vale.ini` |
| Trailing whitespace | Auto-fixed; re-stage and commit |
| Commit message format | Use `feat(scope): description` per Conventional Commits |

### Never Skip These Hooks

- `detect-aws-credentials` — prevents leaked AWS credentials
- `detect-private-key` — prevents leaked private keys
- `scan-secrets` — scans entire git history for secrets
- `terraform_validate` — ensures Terraform modules are syntactically valid
- `no-commit-to-branch` — enforces PR workflow (no direct commits to main)

Use `git commit --no-verify` only in genuine emergencies, and report the issue immediately.

### Conventional commit hook implementation

Commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```text
<type>(<scope>): <description>

optional body

optional footer
```

**Valid types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Examples:**

✅ `feat(s3-bucket): add KMS encryption support`
✅ `fix(vpc): correct CIDR validation logic`
❌ `Updated stuff` (too vague)
❌ `fix bug` (missing scope)

For more details, see [Pre-Commit Hooks Reference](docs/user-guides/Pre_commit_hooks_reference.md#commit-messages).
| `trailing-whitespace` | Remove trailing whitespace |
| `check-yaml` | Validate YAML syntax |
| `mixed-line-ending` | Enforce LF line endings |
| `detect-aws-credentials` | Catch accidentally committed credentials |
| `detect-private-key` | Catch committed private keys |
| `gitleaks` | Scan for secrets |
| `shellcheck` | Lint shell scripts |
| `editorconfig-checker` | Enforce `.editorconfig` rules |
| `markdownlint` | Lint Markdown files |
| `vale` | Check English prose style |
| `conventional-commit` | Native bash validation script for conventional commit messages |

### Conventional commits

Commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```text
type(scope): description

[optional body]
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

#### Implementation Notes

The `conventional-commit` hook is implemented as a native bash script ([`scripts/githooks/validate-conventional-commit.sh`](scripts/githooks/validate-conventional-commit.sh)) rather than using an external dependency. This provides:

- **Supply chain security** — Eliminates dependency on external pre-commit packages
- **No Docker overhead** — Pure bash, no container orchestration
- **Fast validation** — Minimal overhead compared to external tools
- **Can be audited** — Full source visible, easy to customise

### Commit message tooling (recommended)

To make writing conventional commit messages easier, install one of the following interactive helpers. These provide a guided prompt when you run `git commit` so you don't have to remember the format manually.

#### Option A — Commitizen (Python)

[Commitizen](https://github.com/commitizen-tools/commitizen) provides an interactive CLI and can also bump versions and generate changelogs.

```shell
# Install via pip (or pipx for isolation)
pipx install commitizen

# Use instead of `git commit`
cz commit
```

Pair with [commitlint](https://github.com/conventional-changelog/commitlint) for CI-level validation:

```shell
npm install -g @commitlint/cli @commitlint/config-conventional
echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js
```

#### Option B — git-cz (Node.js)

[git-cz](https://github.com/streamich/git-cz) is a lightweight, zero-config interactive commit prompt:

```shell
# Install globally
npm install -g git-cz

# Use instead of `git commit`
git cz
```

> [!TIP]
> Whichever tool you choose, the `conventional-commit` hook in `.pre-commit-config.yaml` will still validate the final message at commit time, so these tools complement rather than replace the hook.

## Security and Supply Chain

### GitHub Actions Pinning

All GitHub Actions in CI/CD workflows are pinned to immutable commit SHAs rather than version tags, with version comments for human readability:

```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
- uses: jdx/mise-action@dba19683ed58901619b14f395a24841710cb4925 # v4.1.0
```

This prevents tag relinking attacks and supply chain compromises. Version comments are maintained for readability when reviewing workflows.

### Pre-commit Hook Pinning

All external pre-commit repositories are pinned to commit SHAs:

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: d61ded22bf9aa0f757303ebcbb0d6d71c4b54015 # v1.106.0
```

### Local Hook Implementation

Custom hooks are implemented as local scripts where practical:

- `scripts/githooks/validate-conventional-commit.sh` — Native bash conventional commit validation script
- `scripts/githooks/generate-terraform-providers.sh` — Local provider alias generator
- `scripts/githooks/check-dependabot-config.sh` — Regenerates Dependabot configuration when modules change

This reduces external dependencies and improves supply chain security.

### Verification

To verify pinning compliance:

```shell
make test-workflow-pinning
bash tests/test-workflow-security.sh verbose
```

## Contributing

1. Create a feature branch from `main`.
2. Run `pre-commit run --all-files` before pushing.
3. Ensure commit messages follow the [Conventional Commits](#conventional-commits) format.
4. Open a pull request — the `pre-commit.yml` workflow will validate all hooks pass.
5. All modules must include the required files listed in [Module layout](#module-layout) and meet the [security baseline](#wrapper-module-pattern).

For detailed module authoring guidance, see `infrastructure/AGENTS.md`.

### Dependabot Policy

Dependabot configuration is automatically maintained in `.github/dependabot.yaml` and kept in sync with all modules in `infrastructure/modules/` through the `regenerate-dependabot-config` pre-commit hook.

#### Automatic Configuration Discovery

The `.github/dependabot.yaml` configuration is regenerated automatically whenever module `versions.tf` files change. This ensures Dependabot watches all Terraform modules without manual maintenance:

```bash
# Generate configuration manually if needed
scripts/generate-dependabot-config.sh
```

The generator:

- Scans `infrastructure/modules/` recursively for all `versions.tf` files
- Excludes `.terraform/` cache directories (downloaded dependencies)
- Creates a Dependabot entry for each module
- Preserves non-Terraform ecosystems (Docker, GitHub Actions, npm, pip)

#### When You Add a New Module

1. Create your module with `infrastructure/modules/<module-name>/versions.tf`
2. Commit your changes
3. The `regenerate-dependabot-config` pre-commit hook runs automatically
4. If new modules are found, the hook regenerates `.github/dependabot.yaml` and fails the commit
5. Review the updated config and commit it:

```bash
git add .github/dependabot.yaml
git commit -m "chore: update Dependabot configuration"
```

#### Testing Configuration Generation

Test the Dependabot configuration system locally:

```bash
bash tests/test-generate-dependabot-config.sh
```

For details, see the Dependabot Configuration Generation Tests section in the testing documentation.

#### Dependabot PR Handling

For Dependabot PRs, the `CI/CD - On Pull Request` workflow runs core validation checks (metadata, pre-commit/coding standards, and validation tests).
Privileged report-upload jobs in coding standards are skipped for Dependabot because they rely on sensitive upload configuration intended for trusted human-driven flows.

This keeps automated dependency updates fully validated without granting unnecessary privileged execution paths to bot-authored PRs.

## Contacts

Raise an issue or open a GitHub discussion on this repository.

## Licence

Unless stated otherwise, the codebase is released under the MIT License. This covers both the codebase and any sample code in the documentation.

Any HTML or Markdown documentation is [© Crown Copyright](https://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/) and available under the terms of the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
