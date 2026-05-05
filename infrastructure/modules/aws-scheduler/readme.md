# AWS scheduler

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.scheduler_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.scheduler_lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_scheduler_schedule.env_expiry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_lambda_function.lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_function_name"></a> [function_name](#input_function_name) | Lambda function name | `string` | n/a | yes |
| <a name="input_lambda_inputs"></a> [lambda_inputs](#input_lambda_inputs) | Map of key-value pairs to send to the Lambda as input | `map(string)` | `{}` | no |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | Prefix for naming resources | `string` | n/a | yes |
| <a name="input_resource_suffix"></a> [resource_suffix](#input_resource_suffix) | Sanitized environment name for resource naming | `string` | n/a | yes |
| <a name="input_schedule_expression"></a> [schedule_expression](#input_schedule_expression) | Schedule expression for the AWS Scheduler (e.g. rate(3 days) or cron(...)) | `string` | `null` | no |
| <a name="input_start_time"></a> [start_time](#input_start_time) | RFC3339 timestamp to use as the scheduler start time | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
