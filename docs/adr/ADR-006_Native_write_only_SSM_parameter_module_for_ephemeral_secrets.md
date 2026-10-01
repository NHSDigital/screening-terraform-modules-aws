# ADR-006: Native write-only SSM parameter module for ephemeral secrets

>|              |                                                  |
>| ------------ | ------------------------------------------------ |
>| Date         | `30/09/2026`                                     |
>| Status       | `Proposed`                                       |
>| Deciders     | `Engineering`                                    |
>| Significance | `Security, Construction techniques, Interfaces`  |
>| Owners       |                                                  |

---

- [ADR-006: Native write-only SSM parameter module for ephemeral secrets](#adr-006-native-write-only-ssm-parameter-module-for-ephemeral-secrets)
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

The `ssm-parameter` module wraps `terraform-aws-modules/ssm-parameter/aws` (v2.1.0).
For `SecureString` it uses the provider's write-only `value_wo` argument, so the value is not stored in state.
However, it is only half of the solution:

- The community module declares `value` as a normal input variable. Terraform only lets ephemeral values (from `ephemeral` resources or `ephemeral = true` variables) reach a write-only argument if **every** module layer declares the input as ephemeral. Consumers therefore have to read secrets with non-ephemeral data sources, which **do** store decrypted values in state and plan files.
- `value_wo_version` silently defaults to `1`. Consumers who don't know this never see updated values applied. The workaround in one consumer (`NHSDigital/bcss`) was to derive the version from a SHA-256 of the secret, which puts a fingerprint of each secret into state.

Downstream consumers (for example `NHSDigital/bcss` BCSS-9997) need to copy secrets between SSM paths without Terraform ever storing the plaintext.

## Decision

### Assumptions

- Terraform `>= 1.13` and AWS provider `>= 6.28` are the repository baseline (write-only attributes need Terraform 1.11+; `ephemeral "aws_ssm_parameter"` is available in AWS provider 6.x).
- The community module may change in future; we should not fork it or depend on its internals.

### Drivers

- No secret values or secret-derived hashes in state or plan files.
- Accept ephemeral values end-to-end.
- Fail fast and explicitly rather than silently ignoring value changes.
- Painless migration for existing `ssm-parameter` callers.

### Options

1. **Modify `ssm-parameter` in place.** It would still depend on the community module's non-ephemeral `value` variable, so this doesn't meet the drivers without forking upstream.
2. **Fork `terraform-aws-modules/ssm-parameter`.** We would own a copy of a third-party module and diverge from upstream fixes. Higher maintenance.
3. **New native module `ssm-parameter-wo` declaring `aws_ssm_parameter` directly (selected).** It keeps the same interface and outputs as `ssm-parameter`, adds an ephemeral `value_wo` input, makes `value_wo_version` mandatory for `SecureString`, and includes `moved` blocks for in-place migration.

### Outcome

Option 3. `ssm-parameter` stays unchanged apart from a validation bug fix, for callers that don't need ephemeral inputs. This decision is reversible: if the community module adds ephemeral input support, `ssm-parameter-wo` can be deprecated in its favour.

### Rationale

| Criterion | 1. Modify in place | 2. Fork upstream | 3. New native module |
| --- | --- | --- | --- |
| Ephemeral values end-to-end | ❌ | ✅ | ✅ |
| No hash fingerprints needed | ❌ | ✅ | ✅ |
| No third-party code to maintain | ✅ | ❌ | ✅ |
| Existing callers unaffected | ⚠️ | ✅ | ✅ |
| In-place migration | n/a | ⚠️ | ✅ (`moved` blocks) |
| Effort | S | L | M |

## Consequences

- Two SSM parameter modules exist. The READMEs explain when to use each.
- Callers switching to `ssm-parameter-wo` must supply `value_wo_version` for `SecureString`, and should switch from `value` to `value_wo`.
- `SecureString` outputs (`value`, `raw_value`, `secure_value`) are always `null`.
- Cross-variable rules are variable validations rather than `validations.tf` preconditions, because the provider's own argument checks run before preconditions.
- `terraform test` suites use `command = plan`, because the test framework cannot re-supply ephemeral inputs to the apply phase.

## Compliance

- `make terraform-test module=ssm-parameter-wo` passes.
- In consumers, `terraform state pull` and `terraform show -json <planfile>` contain no plaintext for parameters managed by this module (verified with a test value that should appear 0 times).

## Notes

- Module: [`infrastructure/modules/ssm-parameter-wo`](../../infrastructure/modules/ssm-parameter-wo)
- Terraform docs: ephemeral values and write-only arguments.
- Consumer decision: `NHSDigital/bcss` `infrastructure_v2/docs/adr/ADR-002`.

## Actions

- [ ] Engineering — raise a Jira ticket to review deprecating `ssm-parameter-wo` if the community module adds ephemeral input support.

## Tags

`#security #data #maintainability #simplicity`
