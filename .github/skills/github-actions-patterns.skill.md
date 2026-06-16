---
name: "github-actions-patterns"
description: "Workflow and composite action conventions for screening-terraform-modules-aws. Reference for writing idiomatic CI/CD following repository patterns."
---

# GitHub Actions Patterns Skill

## Workflow Structure

### Standard Terraform Validation Workflow

```yaml
name: Terraform Validation

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
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  format-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~> 1.13"

      - name: Terraform Format Check
        run: terraform fmt -check -recursive infrastructure/modules/

  validate:
    runs-on: ubuntu-latest
    needs: format-check
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~> 1.13"

      - name: Validate Modules
        run: |
          for dir in infrastructure/modules/*/; do
            if [ -f "$dir/versions.tf" ]; then
              echo "::group::Validating $dir"
              terraform -chdir="$dir" init -backend=false
              terraform -chdir="$dir" validate
              echo "::endgroup::"
            fi
          done
```

## Key Patterns

### Path Filtering

Only trigger workflows when relevant files change:

```yaml
on:
  pull_request:
    paths:
      - "infrastructure/modules/**"
      - ".github/workflows/terraform-*.yml"
```

### Permissions (Least Privilege)

```yaml
permissions:
  contents: read        # Read repository code
  pull-requests: write  # Only if posting comments
  id-token: write       # Only if using OIDC auth
```

### Concurrency

Prevent parallel runs for the same branch/PR:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### Matrix Strategy (Multiple Modules)

```yaml
jobs:
  detect-changes:
    outputs:
      modules: ${{ steps.changes.outputs.modules }}
    steps:
      - uses: actions/checkout@v4
      - id: changes
        run: |
          # Detect which module directories have changes
          modules=$(git diff --name-only origin/main... | grep '^infrastructure/modules/' | cut -d'/' -f3 | sort -u | jq -R . | jq -s .)
          echo "modules=$modules" >> "$GITHUB_OUTPUT"

  validate:
    needs: detect-changes
    strategy:
      matrix:
        module: ${{ fromJson(needs.detect-changes.outputs.modules) }}
    steps:
      - uses: actions/checkout@v4
      - run: |
          terraform -chdir="infrastructure/modules/${{ matrix.module }}" init -backend=false
          terraform -chdir="infrastructure/modules/${{ matrix.module }}" validate
```

### Manual Dispatch Inputs

```yaml
on:
  workflow_dispatch:
    inputs:
      module:
        description: "Module to validate (leave empty for all)"
        required: false
        type: string
      terraform_version:
        description: "Terraform version to use"
        required: false
        default: "~> 1.13"
        type: string
```

## Composite Action Pattern

```yaml
# .github/actions/validate-module/action.yml
name: "Validate Terraform Module"
description: "Initialise and validate a Terraform module directory"

inputs:
  module_path:
    description: "Path to the module directory"
    required: true
  terraform_version:
    description: "Terraform version"
    required: false
    default: "~> 1.13"

runs:
  using: composite
  steps:
    - uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ${{ inputs.terraform_version }}

    - name: Init
      shell: bash
      run: terraform -chdir="${{ inputs.module_path }}" init -backend=false

    - name: Validate
      shell: bash
      run: terraform -chdir="${{ inputs.module_path }}" validate

    - name: Format Check
      shell: bash
      run: terraform fmt -check -diff "${{ inputs.module_path }}"
```

## Security Patterns

### No Credentials for Validation

Module validation doesn't require AWS credentials:

```yaml
- run: terraform -chdir="$dir" init -backend=false
- run: terraform -chdir="$dir" validate
```

### Pin Action Versions

Always pin to a specific tag or SHA:

```yaml
# Good
- uses: actions/checkout@v4
- uses: hashicorp/setup-terraform@v3

# Bad
- uses: actions/checkout@main
- uses: hashicorp/setup-terraform@latest
```

### Restrict Workflow Permissions

```yaml
# Repository-level: restrict default permissions
# Workflow-level: explicitly set minimal permissions
permissions:
  contents: read
```

## Release Workflow Pattern

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Semantic Release
        # Release tooling configured via .releaserc.json
        run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Quality Gates Summary

| Check | Tool | When |
| --- | --- | --- |
| Format | `terraform fmt -check` | Every PR |
| Validate | `terraform validate` | Every PR |
| Static analysis | `tflint` | Every PR |
| Secrets scan | `gitleaks` | Every PR + push |
| Shell lint | `shellcheck` | When shell scripts change |
| Workflow lint | `actionlint` | When workflows change |
