# AGENTS.md – infrastructure

## Scope

Guidance for AI agents working under `infrastructure/` in this repository. For repository-wide guidance, see the root `AGENTS.md`.

## Directory Structure

```text
infrastructure/
└── modules/
    ├── tags/               # Naming & tagging context (THE foundation module)
    │   └── exports/
    │       └── context.tf  # File to copy into other modules/stacks
    ├── s3-bucket/          # COMPLIANT exemplar: S3 wrapper
    ├── iam/                # COMPLIANT exemplar: iam policies & roles wrapper
    ├── secrets-manager/    # COMPLIANT exemplar: Secrets Manager wrapper
    ├── kms/                # COMPLIANT exemplar: KMS key wrapper
    ├── sns/                # COMPLIANT exemplar: SNS topic wrapper
    ├── lambda/             # Lambda function module
    ├── ecr/                # ECR repository module
    ├── vpc/                # VPC module
    ├── ecs-cluster/        # ECS Fargate cluster
    ├── rds-instance/       # RDS instance module
    ├── rds-database/       # RDS database module
    ├── sqs/                # SQS queue module
    ├── waf/                # WAF module
    └── ...                 # Additional modules
```

## The Wrapper Module Pattern

This repository's modules are **thin, opinionated wrappers** around well-known community Terraform modules from the registry (e.g., `terraform-aws-modules/*`). The wrapper's job is to:

1. **Enforce security defaults** that cannot be accidentally overridden by consumers.
2. **Provide consistent naming** via `module.this.id` (from the tags module).
3. **Apply consistent tagging** via `module.this.tags`.
4. **Gate creation** via `module.this.enabled` / `create = module.this.enabled`.
5. **Expose a minimal, stable interface** — only variables that consumers genuinely need to vary.

### Anatomy of a Compliant Module

```text
infrastructure/modules/<module-name>/
├── main.tf          # Primary resource/module definitions with security hardening
├── variables.tf     # Inputs with types, descriptions, defaults, validation blocks
├── outputs.tf       # Outputs with descriptions
├── versions.tf      # required_version and required_providers
├── context.tf       # Copied from tags/exports/context.tf (provides module.this)
├── locals.tf        # Derived values (naming logic, computed defaults)
└── README.md        # Usage docs with examples and control table
```

### Exemplar: `s3-bucket/main.tf` Structure

```hcl
################################################################
# S3 bucket
#
# Thin NHS wrapper around the community S3 bucket module that
# enforces the screening platform's baseline controls:
#
#   * Ownership: BucketOwnerEnforced
#   * Encryption: SSE enabled by default
#   * Transport: TLS-only
#   * Versioning: enabled by default
#   * Public access: blocked at all four toggles
#   * Logging: optional
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"

  create_bucket = module.this.enabled
  bucket        = local.bucket_name

  # ... security baseline settings (fixed and enforced) ...

  tags = module.this.tags
}
```

### Key Design Principles

| Principle | Implementation |
| --- | --- |
| Security controls are **enforced** | e.g., `block_public_policy = true` in secrets-manager; public access block always on in S3 |
| Naming is **derived** from context | `module.this.id` or a local that composes from context labels |
| Optional features use **sensible defaults** | e.g., versioning defaults to `true`; encryption defaults to SSE-S3 |
| Variables include **validation** | `validation {}` blocks with regex, `contains()`, range checks |
| Outputs are **stable and documented** | Stable names (`bucket_arn`, `role_arns`) with descriptions |

## Context/Tags Integration

### How `context.tf` Works

Every module includes a `context.tf` file copied from `infrastructure/modules/tags/exports/context.tf`. This file instantiates `module "this"` which provides:

- `module.this.id` – Generated resource name (e.g., `bcss-test-account-default-my-resource`)
- `module.this.tags` – Standard tag map with all NHS-required labels
- `module.this.context` – Full context object passable to child modules
- `module.this.enabled` – boolean creation gate
- `module.this.environment`, `module.this.service`, etc. – Individual label accessors

### Rules for context.tf

1. **Never edit `context.tf` directly** — it is a copy from `tags/exports/context.tf`.
2. Always use `source = "../tags"` (relative) within this repository.
3. Consumer stacks/repositories use the git source with a pinned ref.
4. Override specific labels at the module call site, not inside the module.

## Required Files Per Module

| File | Purpose | Notes |
| --- | --- | --- |
| `main.tf` | Resource/module definitions | Include header comment block describing what the module enforces |
| `variables.tf` | Input variables | Group with `################################################################` banners; include descriptions, types, defaults, validation |
| `outputs.tf` | Output values | Include descriptions; use stable names |
| `versions.tf` | Version constraints | `required_version = ">= 1.13"`, AWS provider `>= 6.42` |
| `context.tf` | Tags/naming context | Copy from `tags/exports/context.tf`; never edit directly |
| `locals.tf` | Computed values | Naming logic, defaults derivation |
| `README.md` | Usage documentation | Include: what's enforced table, usage examples, conventions |

## Security Baseline Requirements

Every new or updated module **must** enforce:

| Control | Requirement |
| --- | --- |
| Encryption at rest | KMS or service-managed encryption enabled; no unencrypted storage |
| Encryption in transit | TLS required; deny non-TLS connections where applicable |
| No public access | Block public access by default; require explicit opt-in if ever needed |
| iam least privilege | Minimal permissions; no `*` actions in managed policies |
| Logging | Enable access/audit logging where the service supports it |
| Tagging | All resources tagged via `module.this.tags` |
| Creation gate | Resources gated by `module.this.enabled` or `create = module.this.enabled` |

## Variable Conventions

```hcl
################################################################
# Section heading (e.g., "Encryption", "Networking", "Naming")
################################################################

variable "meaningful_name" {
  description = "Clear description of what this variable controls and any constraints."
  type        = string
  default     = "sensible-default"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.meaningful_name))
    error_message = "meaningful_name must start with a letter and contain only lowercase alphanumeric characters and hyphens."
  }
}
```

### Rules

- Always include `description` (mandatory).
- Always include explicit `type`.
- Use `validation {}` blocks for constrained inputs (regex, contains, ranges).
- Use `sensitive = true` for secrets/credentials.
- Use `optional()` in object types where applicable.
- Default values should be sensible for a typical NHS screening use case.
- Variables that callers **should not override** are set in `main.tf`, not exposed as variables.

## Version Constraints

```hcl
# versions.tf
terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42"
    }
  }
}
```

- Pin community module versions explicitly in `main.tf` (e.g., `version = "5.13.0"`).
- Use `>=` for Terraform and provider versions in `versions.tf`.
- Update version constraints when new features are required.

## README Convention

Each module's README should include:

1. **Title** — Module name.
2. **Description** — What the module does and what it wraps.
3. **What this module enforces** — Table of security controls.
4. **Usage examples** — Minimal, with-options, and advanced.
5. **Conventions** — Naming logic, defaults, notable behaviours.

See `infrastructure/modules/s3-bucket/README.md` as the canonical example.

## Formatting & Style

- Run `terraform fmt -recursive` before committing.
- Align `=` signs within blocks for readability.
- One blank line between top-level blocks.
- Comments use `#` (not `//`).
- Use `################################################################` banners for section headers in `main.tf` and `variables.tf`.
- Keep one logical concern per file where practical.

## What Agents Should Do

1. Check existing compliant modules (`s3-bucket`, `iam`, `secrets-manager`, `kms`) for patterns before writing new code.
2. New modules must include ALL required files and meet the security baseline.
3. Use the wrapper pattern — wrap community modules, don't reinvent resources.
4. Keep module interfaces minimal — only expose what consumers genuinely need.
5. Enforce security controls that should never be weakened.
6. Add `validation {}` blocks for constrained inputs.
7. Run `terraform fmt -recursive` and `terraform validate`.
8. Update `README.md` when adding or changing module interfaces.
9. Use British English in comments and documentation.

## What Agents Must NOT Do

1. Keep AWS account IDs, ARNs, or secrets out of module code.
2. Do not expose security-critical settings as variables (e.g., `block_public_policy` must stay `true`).
3. Edit `context.tf` directly — it's a copy from the tags module.
4. Create modules without ALL required files.
5. Use `*` in iam policy actions.
6. Break existing module interfaces without a clear migration path.
7. Skip validation blocks on constrained inputs.

## Available Compliant Modules (Reference)

| Module | Wraps | Key Enforcements |
| --- | --- | --- |
| `s3-bucket` | `terraform-aws-modules/s3-bucket/aws` v5.13.0 | TLS-only, SSE, public block, versioning, ownership enforced |
| `iam` | `terraform-aws-modules/iam/aws` v6.6.0 submodules | Context-derived paths, per-policy/role labelling |
| `secrets-manager` | `terraform-aws-modules/secrets-manager/aws` v2.1.0 | Public policy always blocked, context-derived naming |
| `kms` | `terraform-aws-modules/kms/aws` | Key policy, rotation, context naming |
| `sns` | Native resources | Context naming, encryption, policy |

## Downstream Consumers

Modules in this repository are consumed by:

- **`NHSDigital/bcss`** (`infrastructure_v2/`) — via git source with pinned ref tags.

Consumer stacks reference modules as:

```hcl
module "example" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/<name>?ref=v3.0.0"
  context = module.this.context
  # ...
}
```

Always pin `?ref=` to a release tag. Feature branch refs are acceptable only during active development.
