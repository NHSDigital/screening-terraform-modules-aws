# AGENTS.md
<!-- vale off -->

## Scope

This file is for **AI agents** working within the `screening-terraform-modules-aws` repository.
Humans should read `README.md` and documentation under `docs/` for day-to-day guidance.
Keep anything module- or tool-specific in nested `AGENTS.md` files within relevant directories.

## Repository Layout (high level)

At a glance, the main areas are:

- **`infrastructure/modules/`** – Canonical Terraform wrapper modules consumed by downstream NHS Screening repositories (e.g., `NHSDigital/bcss`). Each module enforces NHS platform baseline security defaults and tagging standards.
- **`infrastructure/modules/tags/`** – The context/naming/tagging module. All other modules depend on this. Its `exports/context.tf` is copied into consumer stacks and modules.
- **`.github/workflows/`** – CI/CD pipelines for linting, validation, testing, and releasing modules.
- **`.github/actions/`** – Composite actions for reusable CI logic.
- **`scripts/terraform/`** – Terraform tooling helpers: `upgrade-module.sh` refreshes provider locks and documentation across one or all modules.
- **`scripts/`** – Helper scripts for automation, Docker, Terraform tooling, git hooks, and releases.
- **`tests/`** – Repository-level test harnesses including test runners for conventional commits, workflow security, and module upgrades.
- **`docs/`** – ADRs, developer guides, user guides, and diagrams.

### Nested AGENTS.md Files

- [`infrastructure/AGENTS.md`](infrastructure/AGENTS.md) – Terraform module conventions, quality baseline, and security requirements.

### Copilot Customisation (`.github/`)

- `.github/instructions/` – Auto-applied rules by file pattern (Terraform modules, GitHub Actions).
- `.github/prompts/` – Reusable prompt templates for common tasks (new module, new workflow).
- `.github/agents/` – Specialist agent mode definitions (terraform-modules, cicd-actions).
- `.github/skills/` – Domain knowledge packs (module patterns, CI patterns).

#### Draft Customisation Workflow

Files using a `.draft.md` extension are **not loaded by Copilot** and serve as work-in-progress customisations for team review. This allows developers to propose new instructions, skills, agents, or prompts without affecting other users until the content is finalised.

**Workflow:**

1. Create a file with the `.draft.md` extension (e.g., `terraform-testing.instructions.draft.md`)
2. Raise a PR for team review — the file won't affect Copilot behaviour during testing
3. Once approved, rename to the active extension (e.g., `terraform-testing.instructions.md`)
4. Merge — Copilot now loads it automatically

**Recognised active extensions:** `*.instructions.md`, `*.agent.md`, `*.skill.md`, `*.prompt.md`

Any other extension (including `.draft.md`) is ignored by Copilot.

## What Agents Can / Cannot Do

Agents **can**:

- Propose new Terraform modules or changes to existing modules.
- Update module variables, outputs, documentation, and README files.
- Suggest improvements to CI/CD workflows and composite actions.
- Propose new scripts, Make targets, or test harnesses.
- Run formatting, linting, and validation commands where safe.

Agents **must not**:

- Create, push, or merge branches or pull requests.
- Introduce new technologies, frameworks, or architectural patterns without clearly calling out that an ADR is needed.
- Invent secrets or hardcode real credentials, API keys, account IDs, or configuration values anywhere.
- Modify release/versioning configuration without explicit human approval.
- Remove or weaken existing security baseline controls in modules.

## Working With This Repo

- **Don't guess commands.** Derive them from what's already here:
  - Prefer `Makefile` targets, `scripts/`, `.github/workflows/`, and `.github/actions/`.
  - For Terraform: `terraform fmt -recursive`, `terraform validate`, `terraform init`.
  - Check `.tool-versions` for required tool versions.
- Keep diffs small and focused. Avoid mixing refactors with behaviour changes.
- This is a British NHS project. Default to British English spelling and terminology.
- Use `mise` (or `asdf` as fallback) for tool management — check `.tool-versions` for required versions.

## Quality Expectations

When proposing a change, agents should:

- Keep code formatted and idiomatic (Terraform HCL, Bash, YAML).
- Stick to existing patterns — look at compliant modules (`s3-bucket`, `iam`, `secrets-manager`, `kms`) as exemplars.
- **Run all pre-commit hooks before committing**: `pre-commit run --all-files` (see `.github/skills/pre-commit-hooks.skill.md` for details on each hook).
- Run `terraform fmt -recursive` before committing.
- Run `terraform validate` in affected module directories.
- Lint shell scripts using `shellcheck`.
- Lint GitHub Actions workflows using `actionlint`.
- Suggest at least one extra validation step where appropriate.
- Any required follow-up activities outside the current task's scope should be marked with a `TODO:` comment. The human user should be prompted to create a JIRA ticket ID.

## Module Compliance Tiers

Not all modules in this repository are currently compliant. The following tiers exist:

| Tier | Description | Examples |
| --- | --- | --- |
| **Compliant** | Full wrapper pattern, `context.tf`, security baseline, proper variables/outputs/README | `s3-bucket`, `iam`, `secrets-manager`, `kms`, `sns` |
| **Partially compliant** | Has `context.tf` but may be missing validation, README, or security hardening | `lambda`, `ecr`, `vpc` |
| **Legacy** | Older modules that predate the current conventions; may lack `context.tf` entirely | Various older modules |

New modules **must** be created at the Compliant tier. Existing modules should be upgraded opportunistically.

## Security & Safety

- All agent-generated changes **must** be reviewed and merged by a human.
- Provide a concise, clear summary of the proposed changes for human review (what changed, why, how validated). It should be directly pastable into the PR description and make it clear that AI assistance was used.
- Never output real secrets or tokens. Use placeholders and rely on GitHub/AWS secrets wired into workflows.

## Escalation / Blockers

If you are blocked by an unavailable secret, unclear architectural constraint, missing upstream dependency, or failing tooling you cannot safely fix, stop and ask a single clear clarifying question rather than guessing.
