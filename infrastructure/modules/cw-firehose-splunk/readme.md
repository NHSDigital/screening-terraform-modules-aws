# CW-Firehose-Splunk

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.8.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.47.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.cloudwatch_to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cw_firehose_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cw_lambda_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cloudwatch_to_firehose_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cw_firehose_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cw_lambda_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_to_firehose_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cw_firehose_att](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cw_lambda_att](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kinesis_firehose_delivery_stream.cw_logs_splunk_stream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream) | resource |
| [aws_lambda_function.preprocess-cw-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_s3_bucket.undelivered_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.block_public_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.undelivered_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [local_file.preprocess-cw-logs-py](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [archive_file.preprocess-cw-logs-zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cw_firehose_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cw_firehose_doc_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cw_lambda_doc_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | The AWS account ID | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_exclude_extra_logging"></a> [exclude\_extra\_logging](#input\_exclude\_extra\_logging) | Exclude extra logging information in the Lambda function that preprocesses the CW logs before sending to Splunk | `bool` | `false` | no |
| <a name="input_firehose_splunk_url"></a> [firehose\_splunk\_url](#input\_firehose\_splunk\_url) | URL for splunk | `string` | `"https://firehose.inputs.splunk.aws.digital.nhs.uk/services/collector"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The account, environment etc | `string` | n/a | yes |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | The Python version to use for the Lambda function | `string` | n/a | yes |
| <a name="input_splunk_hec_token"></a> [splunk\_hec\_token](#input\_splunk\_hec\_token) | Splunk HEC token which points to a specific log index in Splunk | `any` | n/a | yes |
| <a name="input_splunk_index"></a> [splunk\_index](#input\_splunk\_index) | Name of the Splunk index to post logs to | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cw_to_splunk_firehose_role_arn"></a> [cw\_to\_splunk\_firehose\_role\_arn](#output\_cw\_to\_splunk\_firehose\_role\_arn) | n/a |
| <a name="output_cw_to_splunk_firehose_stream_arn"></a> [cw\_to\_splunk\_firehose\_stream\_arn](#output\_cw\_to\_splunk\_firehose\_stream\_arn) | n/a |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
