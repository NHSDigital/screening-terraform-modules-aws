---
description: "Create a new Terraform module in infrastructure/modules following the NHS Screening wrapper module conventions"
---

# Create Terraform Module

Create a new module at `infrastructure/modules/{{ module_name }}`.

## Pre-requisites

Before starting, check:

1. Does a suitable community module exist? (e.g., `terraform-aws-modules/<service>/aws`)
2. Is the module genuinely reusable, or should it be inline in a consumer stack?
3. Does a similar module already exist in this repository that could be extended?

## Required Files

Create ALL of the following:

### 1. `main.tf`

```hcl
################################################################
# {{ Module Title }}
#
# Thin NHS wrapper around the community {{ community_module }}
# that enforces the screening platform's baseline controls:
#
#   * {{ Control 1 }}
#   * {{ Control 2 }}
#   * {{ Control 3 }}
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "{{ resource_name }}" {
  source  = "terraform-aws-modules/{{ community_module }}/aws"
  version = "{{ version }}"

  create = module.this.enabled
  name   = module.this.id  # or local.derived_name

  # Platform baseline settings (fixed and enforced)
  # ...

  tags = module.this.tags
}
```

### 2. `variables.tf`

```hcl
################################################################
# {{ Module }}-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "example" {
  description = "Clear description of what this controls."
  type        = string
  default     = "sensible-default"

  validation {
    condition     = can(regex("^[a-z-]+$", var.example))
    error_message = "example must contain only lowercase letters and hyphens."
  }
}
```

### 3. `outputs.tf`

```hcl
output "resource_arn" {
  description = "ARN of the created resource."
  value       = module.{{ resource_name }}.arn
}

output "resource_id" {
  description = "ID of the created resource."
  value       = module.{{ resource_name }}.id
}
```

### 4. `versions.tf`

```hcl
terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= {{ upstream_min_version }}"  # Use the upstream module's minimum; >= 6.42 is the platform baseline
    }
  }
}
```

> **Note:** Use whichever is higher — the upstream community module's stated minimum
> provider version, or the platform baseline of `>= 6.42`. Do not blindly apply the
> platform baseline if the upstream module works correctly at a lower version.

### 5. `context.tf`

Copy from `infrastructure/modules/tags/exports/context.tf`:

```sh
cp infrastructure/modules/tags/exports/context.tf infrastructure/modules/{{ module_name }}/context.tf
```

Then update the copied file so `module "this"` uses `source = "../tags"`:

```sh
sed -i.bak 's|source\s*=\s*".*tags.*"|source = "../tags"|' infrastructure/modules/{{ module_name }}/context.tf && rm -f infrastructure/modules/{{ module_name }}/context.tf.bak
```

Required check (must pass before finalising):

```sh
grep -n 'source\s*=\s*"\.\./tags"' infrastructure/modules/{{ module_name }}/context.tf
```

### 6. `locals.tf`

```hcl
locals {
  # Naming logic — derive from context, allow caller override
  resource_name = var.custom_name != null ? var.custom_name : module.this.id
}
```

### 7. `README.md`

```markdown
# {{ Module Name }}

NHS Screening wrapper around the community
[`terraform-aws-modules/{{ community_module }}/aws`](https://registry.terraform.io/modules/terraform-aws-modules/{{ community_module }}/aws/latest)
module that enforces the platform's baseline controls.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| {{ Control 1 }} | {{ Implementation }} |
| {{ Control 2 }} | {{ Implementation }} |

## Usage

### Minimal

\```hcl
module "{{ module_name }}" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/{{ module_name }}?ref=v{{ version }}"

  context = module.this.context
  # module-specific inputs...
}
\```

### Common production-style

\```hcl
# Include realistic networking/security inputs and context labels.
\```

### Advanced or edge case

\```hcl
# Include a restore/migration/records-only style example relevant to the module.
\```

## Conventions

- Explain naming precedence (e.g. custom name vs context-derived name).
- Explain any enforced defaults callers should be aware of.
- Explain ownership boundaries (what the caller must create/manage).

## What this module does NOT do

- List intentional exclusions and security guardrails.
```

READMEs are incomplete without a `## Usage` section and must not be considered done until Usage, Conventions, and What this module does NOT do are present.

**Markdown formatting:** READMEs must pass the `check-markdown-format` pre-commit hook. Key rules:

- Use compact table style: `|Header|Value|` (no extra spaces around pipes).
- Lists: unordered items use 0-space indentation, nested items use 3-space indentation.
- Blank lines required before and after list blocks.
- Code blocks use triple backticks with language (e.g., ` ```hcl `).
- Run `pre-commit run check-markdown-format --files README.md` before committing.

## Security Checklist

Before finalising, verify the module enforces:

- [ ] Encryption at rest (KMS or service-managed)
- [ ] Encryption in transit (TLS required) where applicable
- [ ] No public access by default
- [ ] IAM least-privilege (no `*` actions)
- [ ] Logging enabled where the service supports it
- [ ] All resources tagged via `module.this.tags`
- [ ] Creation gated by `module.this.enabled`

## Validation

After creating the module:

```sh
# Format
terraform fmt -recursive infrastructure/modules/{{ module_name }}

# Initialise (needed for validate)
terraform -chdir=infrastructure/modules/{{ module_name }} init

# Validate
terraform -chdir=infrastructure/modules/{{ module_name }} validate
```

## Exemplar Modules

Reference these for patterns:

- `infrastructure/modules/s3-bucket` — full wrapper with comprehensive security
- `infrastructure/modules/iam` — multi-resource wrapper with per-resource iteration
- `infrastructure/modules/secrets-manager` — simple wrapper with hard-coded security
- `infrastructure/modules/acm` – simple wrapper with opinionated security defaults
