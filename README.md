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

Tool versions are managed via [mise](https://mise.jdx.dev/). See `.tool-versions` for the pinned versions. The key dependencies are:

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

> [!NOTE]
> On macOS the default GNU make is too old. Install a newer version with `brew install make` and ensure it is on your `$PATH`.

### Tool Version Source of Truth

- Primary source: `.tool-versions`
- Fallback source: `.tool-versions.yml` (used when `.tool-versions` is absent)

Local development and CI both resolve pinned versions from these files through mise.
The `stage-1-pre-commit.yml` workflow installs tools from `.tool-versions` and generates it from `.tool-versions.yml` when required.

### Configuration

```shell
make config
```

This installs Git hooks, configures the local development environment, and prepares the toolchain.

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
├── .pre-commit-config.yaml
├── .generate-providers.sh # Aliased provider generation for validate
├── .tool-versions         # mise/asdf tool versions
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

CI tooling versions are resolved from `.tool-versions` via mise. If `.tool-versions` is not present, the workflow generates it from `.tool-versions.yml` as a fallback.

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

| Hook | Purpose |
| --- | --- |
| `generate-terraform-providers` | Generate `aliased-providers.tf.json` for validation |
| `terraform_fmt` | Enforce canonical Terraform formatting |
| `terraform_tflint` | Static analysis with Terraform-specific rules |
| `terraform_validate` | Validate module configuration |
| `terraform_providers_lock` | Ensure lock files are cross-platform |
| `terraform_docs` | Auto-generate module README documentation |
| `check-added-large-files` | Prevent committing large files |
| `check-merge-conflict` | Detect merge conflict markers |
| `end-of-file-fixer` | Ensure files end with a newline |
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
| `conventional-pre-commit` | Enforce conventional commit messages |

### Conventional commits

Commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```text
type(scope): description

[optional body]
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

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
> Whichever tool you choose, the `conventional-pre-commit` hook in `.pre-commit-config.yaml` will still validate the final message at commit time, so these tools complement rather than replace the hook.

## Contributing

1. Create a feature branch from `main`.
2. Run `pre-commit run --all-files` before pushing.
3. Ensure commit messages follow the [Conventional Commits](#conventional-commits) format.
4. Open a pull request — the `pre-commit.yml` workflow will validate all hooks pass.
5. All modules must include the required files listed in [Module layout](#module-layout) and meet the [security baseline](#wrapper-module-pattern).

For detailed module authoring guidance, see `infrastructure/AGENTS.md`.

## Contacts

Raise an issue or open a GitHub discussion on this repository.

## Licence

Unless stated otherwise, the codebase is released under the MIT License. This covers both the codebase and any sample code in the documentation.

Any HTML or Markdown documentation is [© Crown Copyright](https://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/) and available under the terms of the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
