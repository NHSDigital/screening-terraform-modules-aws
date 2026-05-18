# Security Hub

NHS Screening wrapper around the
[`cloudposse/security-hub/aws`](https://registry.terraform.io/modules/cloudposse/security-hub/aws/latest)
module (pinned to `0.12.2`) so screening services can enable AWS
Security Hub with consistent naming and tagging via the shared
`context.tf`.

This wraps the upstream module in the same way as
[`inspector`](../inspector) wraps `cloudposse/inspector/aws`.

## What this module enforces

| Control                         | How it is enforced                                                       |
| ------------------------------- | ------------------------------------------------------------------------ |
| Consistent naming & tagging     | `context = module.this.context` forwarded to the upstream module         |
| `enabled` switch                | Honoured via `module.this.context.enabled`                               |
| Default standards on by default | `var.enable_default_standards = true` (AWS FSBP + CIS AWS Foundations)   |
| Single source of SNS truth      | `create_sns_topic = false`; findings forwarded to an existing topic arn  |

## Pairing with GuardDuty

GuardDuty findings are automatically ingested by Security Hub once both
services are enabled in the same account/region. Both the
[`guardduty`](../guardduty) and `security-hub` modules forward findings to a
shared SNS topic created by the separate alerting module via the
`findings_notification_arn` input.

## Usage

### Minimal: enable Security Hub with the default standards

```hcl
module "security_hub" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-hub?ref=main"

  service     = "bcss"
  project     = "platform"
  environment = "prod"
  name        = "security-hub"
}
```

### Subscribe to extra standards and aggregate findings across regions

```hcl
module "security_hub" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-hub?ref=main"

  service     = "bcss"
  project     = "platform"
  environment = "prod"
  name        = "security-hub"

  enabled_standards = [
    "standards/pci-dss/v/3.2.1",
  ]

  finding_aggregator_enabled = true
}
```

### Forward imported findings to the shared alerting SNS topic

```hcl
module "security_hub" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-hub?ref=main"

  service     = "bcss"
  project     = "platform"
  environment = "prod"
  name        = "security-hub"

  findings_notification_arn = module.alerting.sns_topic_arn
}
```

## What this module does NOT do

* Create the SNS topic that receives findings. That is owned by the alerting
  module — pass its arn via `findings_notification_arn`.
* Create a KMS key. If the alerting SNS topic is KMS-encrypted, configure that
  inside the alerting module.
* Manage Organization-wide Security Hub administration / member accounts. Those
  belong in a separate account-scope module.

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
<!-- terraform-docs regenerates the content below in CI. -->
<!-- END_TF_DOCS -->
<!-- vale on -->
