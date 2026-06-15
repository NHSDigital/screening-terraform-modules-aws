---
applyTo: "infrastructure/modules/**/*.tf"
---

# Terraform Module Instructions

## Context & Tagging

Every module uses the `context.tf` pattern from `infrastructure/modules/tags/exports/context.tf`.

- Include `context.tf` in every module (copied from the tags module exports — **never edited directly**).
- `context.tf` instantiates `module "this"` with `source = "../tags"` (relative within this repo).
- Use `module.this.enabled` or `create = module.this.enabled` to gate resource creation.
- Use `module.this.id` for resource naming.
- Use `module.this.tags` for resource tagging.
- Pass `context = module.this.context` to child module calls.
- Never use `default_tags` on the provider block.

## Wrapper Module Pattern

Modules in this repository are thin, opinionated wrappers around community Terraform modules:

```hcl
################################################################
# <Resource name>
#
# Thin NHS wrapper around the community <module> that
# enforces the screening platform's baseline controls:
#
#   * <Control 1>
#   * <Control 2>
#   * ...
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "<resource>" {
  source  = "terraform-aws-modules/<name>/aws"
  version = "x.y.z"  # Always pinned explicitly

  create = module.this.enabled
  name   = module.this.id   # or local.derived_name

  # Platform baseline settings (fixed and enforced)
  # ...

  tags = module.this.tags
}
```

### Key Principles

- **Enforce security controls** that should never be weakened (e.g., `block_public_policy = true`).
- **Expose only necessary variables** — if a setting should always be a certain value for NHS compliance, fix it rather than exposing it as a variable.
- **Pin community module versions** explicitly (e.g., `version = "5.13.0"`).

## Naming Conventions

- Use snake_case for all Terraform resource/module/local/variable names.
- Use kebab-case for AWS resource names (handled by the tags module delimiter).
- File naming: one concern per file, named descriptively (`main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `versions.tf`, `context.tf`).
- Variables grouped with `################################################################` comment banner headers.

## Required Module Files

Every module must contain:

| File | Purpose |
| --- | --- |
| `main.tf` | Primary resource definitions with header comment block |
| `variables.tf` | Input variables with types, descriptions, defaults, validations |
| `outputs.tf` | Output values with descriptions |
| `versions.tf` | `required_version` and `required_providers` |
| `context.tf` | Tags context (copied from `tags/exports/context.tf`) |
| `locals.tf` | Derived/computed values (naming, defaults) |
| `README.md` | Usage documentation with examples |

## Variables & Validation

- Always include `description` on variables.
- Always include explicit `type` constraints (`string`, `bool`, `number`, `list(string)`, `map(string)`, `object({...})`).
- Add `validation {}` blocks for constrained inputs (regex patterns, `contains()`, numeric ranges).
- Use `sensitive = true` for secret/credential variables.
- Use `optional()` for optional fields within object types.
- Default values should be sensible for a typical NHS Screening use case.
- Group variables by concern using `################################################################` banner comments.

Example:

```hcl
################################################################
# Encryption
################################################################

variable "kms_master_key_arn" {
  description = "Optional KMS key ARN for encryption. When null, uses service-managed encryption."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days before permanent deletion. Valid: 0 or 7-30."
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 (immediate) or between 7 and 30."
  }
}
```

## Outputs

- Include `description` on all outputs.
- Use stable, predictable names (e.g., `bucket_arn`, `role_arns`, `secret_name`).
- For modules that create multiple resources (e.g., iam), use maps keyed by the logical identifier.

## Version Constraints

```hcl
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

## Security Baseline

Every module must enforce:

- Encryption at rest (KMS or service-managed) where applicable.
- Encryption in transit (TLS required, deny insecure transport) where applicable.
- No public access by default (block at all available toggles).
- iam least-privilege (no `*` actions in managed policies).
- Logging/audit enabled where the service supports it.
- All resources tagged via `module.this.tags`.

## README Documentation

Module READMEs should include:

1. Title and one-line description.
2. "What this module enforces" table (control -> implementation).
3. Usage examples (minimal, with options, advanced).
4. Conventions section explaining naming and notable defaults.

## Formatting & Style

- Run `terraform fmt -recursive` before committing.
- Align `=` signs within blocks for readability.
- One blank line between top-level blocks.
- Comments use `#` (not `//`).
- Use `################################################################` banners for section headers.
- Descriptive header comment block at the top of `main.tf` listing what the module enforces.

## Exemplar Modules

When in doubt, look at these compliant modules for reference:

- `infrastructure/modules/s3-bucket` — Full wrapper with security table, locals-based naming, validation.
- `infrastructure/modules/iam` — Multi-resource wrapper (policies + roles) with per-resource iteration and label modules.
- `infrastructure/modules/secrets-manager` — Simple wrapper with hard-coded security and optional features.
- `infrastructure/modules/kms` — KMS key wrapper with policy enforcement.
