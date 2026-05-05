# Lambda

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda_function"></a> [lambda_function](#module_lambda_function) | terraform-aws-modules/lambda/aws | 8.7.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role_policy_attachment.lambda_to_cw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.push_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vpc_access_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input_environment) | Values to set in the Lambda function environment | `map(string)` | `{}` | no |
| <a name="input_function_description"></a> [function_description](#input_function_description) | The description for the Lambda function | `string` | n/a | yes |
| <a name="input_function_name"></a> [function_name](#input_function_name) | The name of the Lambda function | `string` | `"uk-forwarder"` | no |
| <a name="input_handler_prefix"></a> [handler_prefix](#input_handler_prefix) | The prefix for the Lambda handler function | `string` | n/a | yes |
| <a name="input_layers"></a> [layers](#input_layers) | List of Lambda Layer ARNs to attach to the function | `list(string)` | `[]` | no |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | the prefix standard | `string` | n/a | yes |
| <a name="input_python_version"></a> [python_version](#input_python_version) | The Python version to use for the Lambda function | `string` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input_timeout) | Timeout for the Lambda function in seconds | `number` | `120` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc_security_group_ids](#input_vpc_security_group_ids) | List of VPC security group IDs for the Lambda function | `list(string)` | `[]` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc_subnet_ids](#input_vpc_subnet_ids) | List of VPC subnet IDs for the Lambda function | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output_arn) | n/a |
| <a name="output_function_name"></a> [function_name](#output_function_name) | n/a |
| <a name="output_lambda_arn"></a> [lambda_arn](#output_lambda_arn) | n/a |
| <a name="output_lambda_log_group_name"></a> [lambda_log_group_name](#output_lambda_log_group_name) | n/a |
| <a name="output_role_name"></a> [role_name](#output_role_name) | n/a |
<!-- END_TF_DOCS -->
