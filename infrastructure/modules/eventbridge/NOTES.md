# Implementation Notes

DAVEH: rm or tidy

These notes are about v4.3.2 of the underlying `terraform-aws-modules/terraform-aws-eventbridge` community module.

The main on/off switch is called `create`.

## Underlying resources

### `aws_cloudwatch_event_bus.this`

- data/resource
- gated by `var.create_bus`; can otherwise add to an existing bus
- named by `var.bus_name`
  - default account bus (created by AWS) is named `default`
- events on the bus are encrypted by `var.kms_key_identifier`
  - can be the key ARN, KeyId, key alias, or key alias ARN

### `aws_cloudwatch_event_api_destination.this`

- resource
- gated by `var.create_api_destinations`
- named by `var.api_destinations` keys
  - modified if `var.append_destination_postfix` is true

### `aws_cloudwatch_event_archive.this`

- resource
- gated by `var.create_archives`
- named by `name` field of `var.archives` sub-value, falling back to `var.archives` key
- encrypted using `kms_key_identifier` field of `var.archives` sub-value, falling back to unencrypted

### `aws_cloudwatch_event_connection.this`

- resource
- gated by `var.create_connections`
- named by `Name` field of `var.connections` sub-value
  - modified if `var.append_connection_postfix` is true
- encrypted using `kms_key_identifier` field of `var.archives` sub-value, falling back to unencrypted

### `aws_cloudwatch_event_permission.this`

- resource
- gated by `var.create_permissions`

### `aws_cloudwatch_event_rule.this`

- resource
- gated by `var.create_rules`
- named by `var.rules` key
  - modified if `var.append_rule_postfix` is true

### `aws_cloudwatch_event_target.this`

### `aws_cloudwatch_log_delivery.this`

### `aws_cloudwatch_log_delivery_destination.this`

### `aws_cloudwatch_log_delivery_source.this`

### `aws_iam_policy.additional_inline`

### `aws_iam_policy.additional_json`

### `aws_iam_policy.additional_jsons`

### `aws_iam_policy.api_destination`

### `aws_iam_policy.cloudwatch`

### `aws_iam_policy.ecs`

### `aws_iam_policy.kinesis`

### `aws_iam_policy.kinesis_firehose`

### `aws_iam_policy.lambda`

### `aws_iam_policy.service`

### `aws_iam_policy.sfn`

### `aws_iam_policy.sns`

### `aws_iam_policy.sqs`

### `aws_iam_policy.tracing`

### `aws_iam_policy_attachment.additional_inline`

### `aws_iam_policy_attachment.additional_json`

### `aws_iam_policy_attachment.additional_jsons`

### `aws_iam_policy_attachment.api_destination`

### `aws_iam_policy_attachment.cloudwatch`

### `aws_iam_policy_attachment.ecs`

### `aws_iam_policy_attachment.kinesis`

### `aws_iam_policy_attachment.kinesis_firehose`

### `aws_iam_policy_attachment.lambda`

### `aws_iam_policy_attachment.service`

### `aws_iam_policy_attachment.sfn`

### `aws_iam_policy_attachment.sns`

### `aws_iam_policy_attachment.sqs`

### `aws_iam_policy_attachment.tracing`

### `aws_iam_role.eventbridge`

### `aws_iam_role.eventbridge_pipe`

### `aws_iam_role_policy_attachment.additional_many`

### `aws_iam_role_policy_attachment.additional_one`

### `aws_pipes_pipe.this`

### `aws_scheduler_schedule.this`

### `aws_scheduler_schedule_group.this`

### `aws_schemas_discoverer.this`
