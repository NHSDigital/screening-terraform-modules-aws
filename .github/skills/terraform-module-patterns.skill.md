---
name: "terraform-module-patterns"
description: "Terraform module coding patterns and conventions specific to screening-terraform-modules-aws. Reference for writing idiomatic modules following the repository's established wrapper patterns."
---

# Terraform Module Patterns Skill

## The Wrapper Module Pattern

This repository's modules are thin, opinionated wrappers around community Terraform modules. The wrapper enforces NHS Screening platform defaults while exposing only what consumers need.

### Main.tf Structure

```hcl
################################################################
# <Resource Description>
#
# Thin NHS wrapper around the community <module name> that
# enforces the screening platform's baseline controls:
#
#   * <Control 1: e.g., Ownership: BucketOwnerEnforced>
#   * <Control 2: e.g., Encryption: SSE enabled by default>
#   * <Control 3: e.g., Transport: TLS-only>
#   * <Control 4: e.g., Public access: blocked at all toggles>
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "<resource_name>" {
  source  = "terraform-aws-modules/<service>/aws"
  version = "x.y.z"  # Always pinned

  create = module.this.enabled
  name   = module.this.id   # or local.derived_name

  # ----------------------------------------------------------------
  # <Control Category>
  # ----------------------------------------------------------------
  hardcoded_security_setting = true

  # ----------------------------------------------------------------
  # <Another Control Category>
  # ----------------------------------------------------------------
  another_setting = "enforced-value"

  # ----------------------------------------------------------------
  # Optional pass-throughs (caller-controlled)
  # ----------------------------------------------------------------
  optional_feature = var.optional_feature

  tags = module.this.tags
}
```

### Design Decisions

| Decision | Rationale |
| --- | --- |
| Enforce security controls | Prevents consumers from accidentally weakening the security posture |
| Use `module.this.id` for naming | Consistent naming across all resources, derived from context labels |
| Pin community module versions | Prevents unexpected breaking changes from upstream |
| Use `create = module.this.enabled` | Allows consumers to conditionally disable entire modules |
| Expose minimal interface | Reduces cognitive load and prevents misuse |

## Context/Tags Integration

### How It Works

Every module includes `context.tf` (copied from `tags/exports/context.tf`). This file instantiates `module "this"` providing:

```hcl
# Generated ID (e.g., "bcss-test-account-default-my-resource")
module.this.id

# Standard tag map with all NHS-required labels
module.this.tags

# Full context object passable to child modules
module.this.context

# Boolean creation gate
module.this.enabled

# Individual label accessors
module.this.environment
module.this.service
module.this.project
module.this.stack
module.this.region
```

### In This Repository (Relative Source)

```hcl
# context.tf (within infrastructure/modules/<name>/)
module "this" {
  source = "../tags"

  service     = var.service
  project     = var.project
  environment = var.environment
  # ... all label variables ...
  context = var.context
}
```

### In Consumer Stacks (Git Source)

```hcl
# context.tf (in downstream stacks)
module "this" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags?ref=v3.0.0"
  # ... label variables ...
  context = var.context
}
```

### Calling This Repository's Modules from Consumers

```hcl
module "my_bucket" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/s3-bucket?ref=v3.0.0"

  # Pass context for naming/tagging inheritance
  context = module.this.context

  # Override specific labels for this resource
  name       = "audit-data"
  attributes = ["primary"]

  # Module-specific inputs
  kms_master_key_arn = module.kms.key_arn
}
```

## Variable Declaration Pattern

```hcl
################################################################
# <Section heading> (e.g., "Encryption", "Networking")
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

### Variable Design Rules

- Only expose what consumers genuinely need to vary.
- Security controls that should never change → set in `main.tf`.
- Optional features → use `null` default with conditional logic.
- Complex types → use `object({})` with `optional()` fields.
- Sensitive values → mark with `sensitive = true`.

## Locals Pattern

```hcl
################################################################
# Local values
#
# <Brief description of what these locals compute>
################################################################

data "aws_region" "current" {}

locals {
  # Naming — allow caller override, fall back to context-derived name
  resource_name = var.custom_name != null ? var.custom_name : module.this.id

  # Conditional configuration — compute based on input combinations
  encryption_config = var.kms_key_arn != null ? {
    kms_key_id = var.kms_key_arn
  } : {
    # Service-managed encryption
  }
}
```

## Multi-Resource Module Pattern (iam example)

For modules creating multiple resources of the same type:

```hcl
# Per-resource label modules for stable naming
module "policy_label" {
  source   = "../tags"
  for_each = var.policies

  context    = module.this.context
  attributes = concat(module.this.attributes, ["policy", each.key])
}

# Resources using iteration
module "policies" {
  source   = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version  = "6.6.0"
  for_each = module.this.enabled ? var.policies : {}

  name   = module.policy_label[each.key].id
  policy = each.value.policy

  tags = module.policy_label[each.key].tags
}
```

## Outputs Pattern

```hcl
# Single-resource outputs
output "resource_arn" {
  description = "ARN of the created resource."
  value       = module.resource.arn
}

# Multi-resource outputs (map)
output "policy_arns" {
  description = "Map of policy key -> ARN for every policy created."
  value       = { for k, m in module.policies : k => m.arn }
}
```

## versions.tf Pattern

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

## README Pattern

```markdown
# <Module Name>

NHS Screening wrapper around the community
[`terraform-aws-modules/<name>/aws`](registry-link)
module that enforces the platform's baseline controls.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| <Control> | <Implementation detail> |

## Usage

### Minimal (defaults only)

\```hcl
module "example" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/<name>?ref=main"

  service     = "bcss"
  environment = "test"
  name        = "my-resource"
}
\```

### With options

\```hcl
module "example" {
  source = "..."

  context        = module.this.context
  kms_key_arn    = module.kms.key_arn
  optional_thing = "value"
}
\```

## Conventions

* <Notable naming/default behaviours>
* <Important constraints>
```

## Security Patterns

### Enforced Controls

```hcl
# S3: Public access always blocked
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true

# Secrets Manager: Public policy always blocked
block_public_policy = true

# S3: TLS always required
attach_deny_insecure_transport_policy = true
attach_require_latest_tls_policy      = true
```

### Conditional Controls (Configurable)

```hcl
# KMS encryption: optional but with secure default
server_side_encryption_configuration = var.kms_master_key_arn != null ? {
  rule = {
    apply_server_side_encryption_by_default = {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_master_key_arn
    }
  }
} : {
  rule = {
    apply_server_side_encryption_by_default = {
      sse_algorithm = "AES256"
    }
  }
}
```
