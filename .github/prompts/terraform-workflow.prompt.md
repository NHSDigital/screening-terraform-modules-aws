---
description: "Create or update a GitHub Actions workflow for Terraform validation and CI in this repository"
---

# Terraform Workflow

Create or update a GitHub Actions workflow for validating Terraform modules in this repository.

## Purpose

Workflows in this repository ensure module quality through automated checks:

1. **Format check** — `terraform fmt -check -recursive`
2. **Validate** — `terraform validate` on changed modules
3. **Static analysis** — `tflint` for additional rule enforcement
4. **Security scanning** — detect hard-coded secrets or insecure patterns

## Workflow Template

```yaml
name: Terraform Module Validation

on:
  pull_request:
    paths:
      - "infrastructure/modules/**"
  push:
    branches: [main]
    paths:
      - "infrastructure/modules/**"
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: terraform-${{ github.ref }}
  cancel-in-progress: true

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: "~> 1.13"

      - name: Terraform Format Check
        run: terraform fmt -check -recursive infrastructure/modules/

      - name: Validate Changed Modules
        run: |
          for dir in infrastructure/modules/*/; do
            if [ -f "$dir/versions.tf" ]; then
              echo "Validating $dir"
              terraform -chdir="$dir" init -backend=false
              terraform -chdir="$dir" validate
            fi
          done
```

## Key Requirements

- Use path filters to only trigger on module file changes.
- Set `permissions: contents: read` (least privilege).
- Use `concurrency` groups to cancel superseded runs.
- Include `workflow_dispatch` for manual execution.
- Pin action versions to specific tags.
- Use `-backend=false` for validation (no AWS credentials needed).

## Existing Actions to Consider

Check `.github/actions/` for any existing composite actions that can be reused.

## Validation

- Lint the workflow with `actionlint` before committing.
- Verify the workflow triggers correctly on module file changes.
