# Implementation Notes

DAVEH: rm or tidy

These notes are about v4.3.2 of the underlying `terraform-aws-modules/terraform-aws-eventbridge` community module.

The main on/off switch is called `create`.

## Underlying resources

### `aws_cloudwatch_event_bus.this`

- data/resource
- gated by `var.create_bus`; can otherwise add to an existing bus
- name status: named and must be unique per AWS account and region
- named by `var.bus_name`
  - default account bus (created by AWS) is named `default`
- events on the bus are encrypted by `var.kms_key_identifier`
  - can be the key ARN, KeyId, key alias, or key alias ARN

### `aws_cloudwatch_event_api_destination.this`

- resource
- gated by `var.create_api_destinations`
- name status: named and must be unique per AWS account and region
- named by `var.api_destinations` keys
  - modified if `var.append_destination_postfix` is true

### `aws_cloudwatch_event_archive.this`

- resource
- gated by `var.create_archives`
- name status: named and must be unique per event bus
- named by `name` field of `var.archives` sub-value, falling back to `var.archives` key
- encrypted using `kms_key_identifier` field of `var.archives` sub-value, falling back to unencrypted

### `aws_cloudwatch_event_connection.this`

- resource
- gated by `var.create_connections`
- name status: named and must be unique per AWS account and region
- named by `Name` field of `var.connections` sub-value
  - modified if `var.append_connection_postfix` is true
- encrypted using `kms_key_identifier` field of `var.connections` sub-value, falling back to unencrypted

### `aws_cloudwatch_event_permission.this`

- resource
- gated by `var.create_permissions`
- name status: unnamed; its statement ID must be unique on the event bus

### `aws_cloudwatch_event_rule.this`

- resource
- gated by `var.create_rules`
- name status: named and must be unique per event bus
- named by `var.rules` key
  - modified if `var.append_rule_postfix` is true

### `aws_cloudwatch_event_target.this`

- name status: unnamed; its target ID must be unique per rule on an event bus

### `aws_cloudwatch_log_delivery.this`

- name status: unnamed; one delivery is allowed per source-destination pair

### `aws_cloudwatch_log_delivery_destination.this`

- name status: named and must be unique per AWS account

### `aws_cloudwatch_log_delivery_source.this`

- name status: named and must be unique per AWS account

### `aws_iam_policy.additional_inline`

- name status: named and must be unique per AWS account

### `aws_iam_policy.additional_json`

- name status: named and must be unique per AWS account

### `aws_iam_policy.additional_jsons`

- name status: named and must be unique per AWS account

### `aws_iam_policy.api_destination`

- name status: named and must be unique per AWS account

### `aws_iam_policy.cloudwatch`

- name status: named and must be unique per AWS account

### `aws_iam_policy.ecs`

- name status: named and must be unique per AWS account

### `aws_iam_policy.kinesis`

- name status: named and must be unique per AWS account

### `aws_iam_policy.kinesis_firehose`

- name status: named and must be unique per AWS account

### `aws_iam_policy.lambda`

- name status: named and must be unique per AWS account

### `aws_iam_policy.service`

- name status: named and must be unique per AWS account

### `aws_iam_policy.sfn`

- name status: named and must be unique per AWS account

### `aws_iam_policy.sns`

- name status: named and must be unique per AWS account

### `aws_iam_policy.sqs`

- name status: named and must be unique per AWS account

### `aws_iam_policy.tracing`

- name status: named and must be unique per AWS account

### `aws_iam_policy_attachment.additional_inline`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.additional_json`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.additional_jsons`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.api_destination`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.cloudwatch`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.ecs`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.kinesis`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.kinesis_firehose`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.lambda`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.service`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.sfn`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.sns`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.sqs`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_policy_attachment.tracing`

- name status: unnamed; this is an attachment relationship identified by the policy and target ARNs

### `aws_iam_role.eventbridge`

- name status: named and must be unique per AWS account

### `aws_iam_role.eventbridge_pipe`

- name status: named and must be unique per AWS account

### `aws_iam_role_policy_attachment.additional_many`

- name status: unnamed; this is an attachment relationship identified by the role and policy ARNs

### `aws_iam_role_policy_attachment.additional_one`

- name status: unnamed; this is an attachment relationship identified by the role and policy ARNs

### `aws_pipes_pipe.this`

- name status: named and must be unique per AWS account and region
- encrypted using `kms_key_identifier` field of `var.pipes` sub-value, falling back to unencrypted

### `aws_scheduler_schedule.this`

- name status: named and must be unique per schedule group
- encrypted using `kms_key_arn` field of `var.schedules` sub-value, falling back to unencrypted

### `aws_scheduler_schedule_group.this`

- name status: named and must be unique per AWS account and region

### `aws_schemas_discoverer.this`

- name status: named and must be unique per AWS account and region
