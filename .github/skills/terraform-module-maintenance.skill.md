---
name: "terraform-module-maintenance"
description: "Terraform module maintenance workflows: upgrading providers, refreshing documentation, managing module versions, and diagnosing module issues. Reference for keeping modules current and compliant with NHS baseline standards."
---

# Terraform Module Maintenance Skill

## Overview

Module maintenance ensures that Terraform wrapper modules stay current, secure, and compliant with NHS baseline requirements. This skill covers upgrading dependencies, refreshing documentation, and addressing module drift.

## Dependency Upgrade Workflow

### Prerequisites

- `terraform` (see `.tool-versions` for pinned version)
- `terraform-docs`
- `pre-commit` hooks installed
- All Terraform providers cached locally (`.terraform` directories may exist)

### Single Module Upgrade

```bash
./scripts/terraform/upgrade-module.sh infrastructure/modules/<name>
```

This executes:

1. **Initialize with upgrade**: `terraform init -upgrade` fetches latest upstream versions
2. **Lock providers** for all target platforms:
   - `linux_amd64`, `linux_arm64` (primary CI/CD platforms)
   - `darwin_amd64`, `darwin_arm64` (macOS development)
   - `windows_amd64` (Windows development — lowest priority)
3. **Regenerate documentation**: `terraform-docs` rewrites the README based on current module variables/outputs
4. **Clean temporary files**: Remove symlinks and temporary artifacts created during doc generation

### Repository-Wide Upgrade

```bash
./scripts/terraform/upgrade-module.sh update-all
```

Prompts for confirmation, then upgrades all modules under `infrastructure/modules/` in sequence. Useful for bulk provider version bumps (e.g., AWS provider 6.42 → 6.50).

### After Upgrade

Verify the changes before committing:

```bash
# Check what changed
git diff infrastructure/modules/*/versions.tf
git diff infrastructure/modules/*/.terraform.lock.hcl

# Validate all modules
for dir in infrastructure/modules/*/; do
  [ -f "$dir/versions.tf" ] && terraform -chdir="$dir" init -backend=false && terraform -chdir="$dir" validate
done

# Run full test suite
bash tests/run-all-tests.sh
```

## Version Pinning

### Community Module Versions

In each module's `main.tf`, pin the community module version explicitly:

```hcl
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"  # Always pinned; no ~>, >=, or wildcards
  # ...
}
```

When upgrading:

1. Update the version in `main.tf`
2. Run `terraform init -upgrade` to refetch
3. Review changes in `.terraform.lock.hcl` and module outputs
4. Test and validate before committing

### Terraform & Provider Constraints

In each module's `versions.tf`:

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

Use `>=` for flexibility; the lock file pins exact versions for reproducibility.

## Documentation Maintenance

The upgrade helper runs `terraform-docs` automatically, but you can regenerate docs manually:

```bash
cd infrastructure/modules/s3-bucket/
terraform-docs markdown . > README.md
```

Pre-commit hooks will validate that README.md is in sync with the module's variables/outputs on every commit.

## Compliance & Security Review

After upgrading a module:

1. **Check security baseline**: Verify that enforcement controls haven't been weakened
   - Encryption settings still hardcoded
   - Public access blocks still enabled
   - iam policies still minimal (no `*` actions)
2. **Review upstream breaking changes**: Check community module release notes for incompatible API changes
3. **Validate outputs**: Ensure stable output names are preserved; consumers depend on them
4. **Test in context**: If possible, apply the module in a test stack to confirm integration

## Module Lifecycle

| Stage | Actions | Timeline |
| --- | --- | --- |
| **Creation** | Design module, write main/variables/outputs, create context.tf, write README | Sprint 1 |
| **Active** | Respond to feature requests, security updates, breaking changes from upstream | Ongoing |
| **Legacy** | Document deprecation, announce replacement, maintain for backward compatibility | N/A |
| **Retirement** | Remove from templates, migrate consumers, archive | N/A |

## Troubleshooting Common Issues

### Lock File Conflicts

If `.terraform.lock.hcl` shows provider version conflicts:

```bash
# Delete and regenerate
rm infrastructure/modules/*/. terraform.lock.hcl
./scripts/terraform/upgrade-module.sh update-all
```

### Documentation Doesn't Regenerate

Pre-commit may have cached the README:

```bash
# Force regeneration
cd infrastructure/modules/s3-bucket/
rm -f README.md
terraform-docs markdown . > README.md
git add README.md
```

### Provider Mismatch on Darwin/Windows

If local `~/.terraform.d/plugins` has incompatible providers:

```bash
# Use the lock file to enforce correct versions
terraform -chdir="infrastructure/modules/vpc" init
```

The `.terraform.lock.hcl` file ensures Terraform downloads the correct version for your platform.

## Checklist: Completing a Module Upgrade

- [ ] Run `./scripts/terraform/upgrade-module.sh <module>`
- [ ] Review `git diff` for unexpected changes
- [ ] Check for upstream breaking changes in release notes
- [ ] Validate security baseline controls are still enforced
- [ ] Run `terraform validate` in the module
- [ ] Run `bash tests/run-all-tests.sh` to ensure no regressions
- [ ] Commit with a clear message: `chore: upgrade <module> to <version>`
- [ ] Verify pre-commit hooks pass (fmt, docs, security)
- [ ] Push and watch CI/CD pipeline

## References

- [Terraform Providers Lock File](https://www.terraform.io/language/files/dependency-lock)
- [terraform-docs](https://terraform-docs.io/)
- [Community Module Upgrade Guide](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/blob/master/CHANGELOG.md)
