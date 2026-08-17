# SQS

Minimal NHS Screening wrapper for a standard SQS queue used for event delivery
workloads such as GitHub ARC `workflow_job` events. The module keeps the API
small, enables server-side encryption by default, and consumes the shared
`context.tf` for naming and tagging.

## What this module enforces

|Control|How it is enforced|
|---|---|
|Queue type|Creates a standard queue only; FIFO is intentionally excluded|
|Encryption at rest|Enables SQS-managed server-side encryption on the primary queue and optional DLQ|
|Transport security|Applies a queue policy that denies insecure transport|
|Publisher scope|Optional publisher statements are limited to `sqs:SendMessage` on this queue|
|Dead-letter queue|Optional DLQ is wired with the retry policy automatically|
|Tagging|Tags supported resources via `module.this.tags`|
|Creation gate|Resource creation is gated by `module.this.enabled`|

## Usage

### Minimal queue

```hcl
module "workflow_job_queue" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/sqs?ref=<tag>"

  enabled        = local.deploy_github_arc
  name           = "workflow-job-events"
  workspace      = terraform.workspace
  tags           = module.tags.tags
  labels_as_tags = []
}
```

### Queue with publisher permissions

```hcl
module "workflow_job_queue" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/sqs?ref=<tag>"

  enabled        = true
  name           = "workflow-job-events"
  workspace      = terraform.workspace
  tags           = module.tags.tags
  labels_as_tags = []

  publisher_statements = {
    eventbridge = {
      principals = {
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }
      source_arns = [aws_cloudwatch_event_rule.github_arc.arn]
    }
  }
}
```

### Queue with dead-letter queue and tuned settings

```hcl
module "workflow_job_queue" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/sqs?ref=<tag>"

  enabled                    = true
  name                       = "workflow-job-events"
  workspace                  = terraform.workspace
  tags                       = module.tags.tags
  labels_as_tags             = []
  visibility_timeout_seconds = 180
  message_retention_seconds  = 604800
  receive_wait_time_seconds  = 20

  dead_letter_queue = {
    create            = true
    max_receive_count = 3
  }
}
```

## Conventions

* `custom_name` is optional. When omitted, the queue name is derived from
  `module.this.id` so stacks can consume the module with the same ergonomics as
  other wrappers in this repository.
* Long polling defaults to `20` seconds to reduce empty receives for event-driven
  consumers.
* When `dead_letter_queue.create = true`, the DLQ name is derived automatically
  as `<queue-name>-dlq` and the retry policy is applied to the primary queue.
* Publisher policy statements are optional and constrained to `sqs:SendMessage`
  so the module stays generic without becoming a full IAM policy builder.

## What this module does NOT do

* Create FIFO queues or content-based duplicate-message suppression settings.
* Support arbitrary queue policy JSON or arbitrary IAM actions.
* Support custom KMS keys, SNS subscriptions, or EventBridge rules.
* Attach policies to the DLQ separately from the primary queue.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.13 |
| aws | >= 6.42 |

## Outputs

| Name | Description |
| ---- | ----------- |
| queue_id | The ID of the primary queue. For SQS this is the queue URL identifier. |
| queue_arn | The ARN of the primary queue. |
| queue_url | The URL of the primary queue. |
| queue_name | The name of the primary queue. |
| dlq_arn | The ARN of the dead-letter queue when created, otherwise null. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
