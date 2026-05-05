# SNS

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
| [aws_sns_topic.sns_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws_account_id](#input_aws_account_id) | The AWS account ID | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | The account, environment etc | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_arn"></a> [sns_topic_arn](#output_sns_topic_arn) | n/a |
| <a name="output_sns_topic_name"></a> [sns_topic_name](#output_sns_topic_name) | n/a |
<!-- END_TF_DOCS -->
<!-- vale on -->
