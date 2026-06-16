---
description: "Refresh Terraform module provider locks and documentation using the upgrade helper"
---

# Refresh Module Providers & Documentation

Use this prompt when AWS provider versions change, community modules receive updates, or pre-commit hooks require documentation regeneration.

## Single Module

To refresh a single module with the latest provider versions and update its README:

```bash
./scripts/terraform/upgrade-module.sh infrastructure/modules/<module-name>
```

**Example:**

```bash
./scripts/terraform/upgrade-module.sh infrastructure/modules/s3-bucket
```

The script will:

1. Fetch latest versions of the module's upstream dependencies
2. Lock Terraform providers for all target platforms (Linux/Darwin × amd64/arm64)
3. Regenerate the module's README.md using `terraform-docs`

## All Modules (Repository-Wide)

To refresh every module at once:

```bash
./scripts/terraform/upgrade-module.sh update-all
```

The script will warn before starting and then iterate through all modules under `infrastructure/modules/`, updating each in sequence.

## After Running

1. Review the changes, particularly:
   - `versions.tf` – provider version changes
   - `.terraform.lock.hcl` – lock file updates
   - `README.md` – documentation regeneration
2. Watch for breaking changes in upstream community modules
3. Run `terraform validate` in each module to confirm correctness
4. Commit the changes with a clear message:

   ```bash
   git add infrastructure/modules/*/
   git commit -m "chore: refresh provider locks and documentation"
   ```

## When to Use

- After updating AWS provider version constraints in `versions.tf`
- After upstream community modules release new versions
- When pre-commit hooks fail on module documentation consistency
- During routine dependency maintenance cycles

## Troubleshooting

If the script fails:

1. Ensure `terraform`, `terraform-docs`, and `pre-commit` are installed and on PATH
2. Check that you're in the repository root directory
3. Verify that `scripts/terraform/upgrade-module.sh` is executable: `chmod +x scripts/terraform/upgrade-module.sh`
4. Run with `bash -x` for detailed debugging: `bash -x ./scripts/terraform/upgrade-module.sh infrastructure/modules/vpc`
