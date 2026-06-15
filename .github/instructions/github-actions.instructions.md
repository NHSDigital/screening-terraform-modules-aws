---
applyTo: ".github/workflows/*.{yml,yaml},.github/actions/**/*.{yml,yaml}"
---

# GitHub Actions Instructions

## Workflow Conventions

- Use YAML extension `.yml` for workflows.
- Lint all workflows with `actionlint` before committing.
- Use composite actions under `.github/actions/` for reusable logic.
- Reference composite actions as `uses: ./.github/actions/<action-name>`.

## Authentication & Secrets

- Never store long-lived AWS credentials as GitHub secrets; rely on OIDC federation where applicable.
- Reference secrets with `${{ secrets.SECRET_NAME }}` — never hard-code values.
- Use environment protection rules for sensitive deployments.

## Terraform in CI

- Ensure workflows validate formatting (`terraform fmt -check`).
- Ensure workflows validate configuration (`terraform validate`).
- Use path filters to only trigger on relevant file changes.
- Consider running `tflint` for additional static analysis.

## Best Practices

- Pin external action versions to SHA or specific tag (not `@main`).
- Use `concurrency` groups to prevent parallel runs for the same branch.
- Keep workflow files focused — one workflow per concern.
- Use `workflow_dispatch` inputs for manual triggers with appropriate inputs.
- Set `permissions` explicitly at workflow or job level (least privilege).
- Never use `permissions: write-all` or similar overly broad permissions.

## Composite Actions

- Composite actions live under `.github/actions/<action-name>/action.yml`.
- Include `description` and typed `inputs`/`outputs`.
- Keep logic focused — one action, one concern.
- Shell scripts called by actions should be `shellcheck`-clean.

## Release & Versioning

- This repository uses semantic versioning.
- Releases are managed through the configured release tooling (`.releaserc.json`, `VERSION`).
- Workflow changes should not affect the release process without explicit consideration.
