# ADR-005: Centralise CI coding checks with pre-commit and aggregated PR status

| | |
| --- | --- |
| Date | `16/06/2026` |
| Status | `RFC by 30/06/2026` |
| Deciders | `Engineering` |
| Significance | `Structure, Nonfunctional characteristics, Construction techniques` |
| Owners | `Engineering team` |

---

- [ADR-005: Centralise CI coding checks with pre-commit and aggregated PR status](#adr-005-centralise-ci-coding-checks-with-pre-commit-and-aggregated-pr-status)
  - [Context](#context)
  - [Decision](#decision)
    - [Assumptions](#assumptions)
    - [Drivers](#drivers)
    - [Options](#options)
    - [Outcome](#outcome)
    - [Rationale](#rationale)
  - [Consequences](#consequences)
  - [Compliance](#compliance)
  - [Notes](#notes)
  - [Actions](#actions)
  - [Tags](#tags)

## Context

The repository previously executed coding standards as multiple separate CI jobs (`scan-secrets`, `check-file-format`, `check-markdown-format`, `check-english-usage`, `lint-terraform`) in stage-1 reusable workflows. This increased maintenance overhead and created drift risk between local checks and CI checks.

At the same time, PR governance needed to improve in two areas:

1. Give contributors visibility when commit messages are not Conventional Commit compliant, without initially blocking merges.
2. Provide a single final status check for branch protection that reflects all required job outcomes and tolerates skipped jobs.

In parallel, incomplete stage-3/stage-4 workflows were held back from execution to avoid partial or misleading CI/CD behavior.

## Decision

### Assumptions

- `pre-commit` remains the single source of truth for coding checks.
- Contributors run hooks locally, but CI must enforce consistency.
- During adoption, Conventional Commit checks should be advisory, not blocking.
- Branch protection should target one stable final status check.

### Drivers

- Reduce duplication and configuration drift.
- Improve CI runtime and maintainability.
- Keep rollback simple and low-risk.
- Make merge gate behavior predictable.

### Options

1. Keep separate stage-1 jobs and maintain them independently.
2. Replace stage-1 coding jobs with `pre-commit` as canonical CI checks.
3. Duplicate checks: keep stage-1 jobs and add pre-commit workflow.

### Outcome

Option 2 is selected.

- Introduce and use `stage-1-pre-commit.yml` as the canonical coding-check workflow.
- Run pre-commit checks in partitioned matrix groups for better CI throughput.
- Make `stage-1-pre-commit.yml` reusable-only (`workflow_call`) to avoid duplicate PR runs.
- Keep legacy stage-1 per-check jobs disabled (not removed) with rollback comments (`if: false`).
- Add non-blocking Conventional Commit advisory in `cicd-1-pull-request.yaml` to review all commit messages in a PR.
- Add `all-checks-complete` final job to aggregate required job results for branch protection.
- Keep incomplete stage-3/stage-4 workflows on hold by non-workflow file suffix.

This is a reversible decision.

### Rationale

Using pre-commit as canonical provides a single policy surface for both local and CI checks. Matrix partitioning improves wall-clock time without forking policy definitions. Keeping legacy jobs disabled (not deleted) allows rapid rollback while migration confidence is built.

The non-blocking Conventional Commit advisory introduces behavioral guidance with minimal disruption. The final aggregate job simplifies branch protection configuration and reduces future maintenance when jobs evolve.

## Consequences

Positive:

- Lower maintenance and less policy drift.
- Faster feedback from partitioned coding checks.
- Cleaner branch protection with one final required check.
- Safer migration through disabled legacy jobs.

Negative / trade-offs:

- Pre-commit matrix partitioning introduces CI orchestration complexity.
- Some checks may still be duplicated temporarily while legacy jobs remain present (though disabled).
- Advisory commit-message checks require future governance decision if/when to enforce strictly.

Decision becomes irrelevant when:

- The repository adopts a different quality-gate framework than pre-commit, or
- Branch protection strategy no longer relies on aggregated workflow status.

## Compliance

Success criteria:

- Stage-1 coding checks run through `stage-1-pre-commit.yml` in CI.
- Legacy stage-1 coding jobs remain disabled and clearly marked for rollback.
- PR workflow exposes `all-checks-complete` and branch protection can use it as required status.
- Conventional Commit advisory reports warnings without failing PR workflow.

Verification approach:

- Manual verification in PR checks for expected job graph.
- YAML lint and pre-commit validation for workflow changes.
- Spot-check PRs with intentionally invalid commit messages to confirm advisory behavior.

## Notes

Related workflow/configuration files:

- `.github/workflows/stage-1-pre-commit.yml`
- `.github/workflows/stage-1-coding-standards.yaml`
- `.github/workflows/stage-1-commit.yaml`
- `.github/workflows/cicd-1-pull-request.yaml`
- `.pre-commit-config.yaml`

Related decisions:

- `ADR-001_Use_git_hook_and_GitHub_action_to_check_the_editorconfig_compliance.md`
- `ADR-002_Scan_repository_for_hardcoded_secrets.md`
- `ADR-003_Acceptable_use_of_GitHub_PAT_and_Apps_for_authN_and_authZ.md`

## Actions

- [x] Engineering, 16/06/2026, implement reusable pre-commit workflow and stage-1 migration
- [x] Engineering, 16/06/2026, add PR advisory commit-message check and final aggregate check
- [ ] Engineering, by 30/06/2026, decide whether Conventional Commit advisory should become a blocking check
- [ ] Engineering, by 30/06/2026, remove legacy disabled stage-1 coding jobs after migration confidence period

## Tags

`#maintainability #testability #deployability #reliability #simplicity #security #cost`
