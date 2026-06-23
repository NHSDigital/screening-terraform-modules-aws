---
applyTo: ".github/workflows/*.{yml,yaml},.github/actions/**/*.{yml,yaml}"
---

# GitHub Actions Instructions

## Workflow Conventions

- Use YAML extension `.yaml` for workflows.
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

## Documentation & README Updates

**Documentation must be updated whenever workflows or actions change.**

### When Adding or Modifying Workflows

1. **Update the root `README.md`** if:
   - You've added a new critical workflow (e.g., release, security scanning)
   - You've changed CI/CD structure or validation steps
   - You've modified how modules are validated or released

2. **Update `docs/user-guides/`** if:
   - You've changed how developers run tests or validate code
   - You've added new CI/CD gates or requirements
   - You've modified module upgrade procedures

### When Adding or Modifying Composite Actions

1. **Include comprehensive action.yml** with:
   - Clear `description` of what the action does
   - All `inputs` with descriptions and defaults
   - All `outputs` with descriptions
   - Example usage patterns

2. **Update related documentation**:
   - If action is used by multiple workflows, document the integration point
   - If action requires special setup (e.g., AWS credentials), document prerequisites
   - Update root README.md if action is significant to development workflow

### Validation Checklist

Before committing workflow or action changes, verify:

- [ ] Workflow/action YAML is valid and formatted
- [ ] `actionlint` passes: `actionlint .github/workflows/ .github/actions/`
- [ ] All external actions are pinned to immutable SHAs (not @main or @vX.Y.Z tags)
- [ ] Composite action includes full description and input/output documentation
- [ ] Root `README.md` updated if workflow is user-facing
- [ ] `docs/` guides updated if procedure changed
- [ ] Workflow/action permissions are minimal (least privilege)
- [ ] All pre-commit hooks pass: `pre-commit run --all-files`
