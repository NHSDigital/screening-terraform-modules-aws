# Lambda

NHS Screening wrapper around the community [`terraform-aws-modules/lambda/aws`](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest) module that enforces the platform's baseline controls and consumes the shared `context.tf` for naming and tagging.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| IAM execution role | Automatically attaches AWS-managed policies for VPC access, CloudWatch Logs, and SQS execution |
| Tagging and naming | Uses shared `context.tf` (`module.this`) for tags and naming |
| Resource enable/disable | Creation gated by `module.this.enabled` |
| Source path convention | Defaults to `../../lambdas/<handler_prefix>/` for consistent repo layout |

## Usage

### Minimal Lambda function

```hcl
module "lambda_processor" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/lambda?ref=<tag>"

  service     = "bcss"
  project     = "data"
  environment = "prod"
  name        = "processor"

  handler_prefix       = "process_records"
  function_description = "Process incoming data records from SQS"
  python_version       = "python3.12"
}
```

### Lambda with VPC and environment variables

```hcl
module "lambda_api" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/lambda?ref=<tag>"

  service     = "bcss"
  project     = "api"
  environment = "prod"
  name        = "handler"

  handler_prefix       = "api_handler"
  function_description = "API Gateway Lambda handler"
  python_version       = "python3.12"
  timeout              = 30

  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.security_group.id]

  environment_variables = {
    DB_ENDPOINT = module.rds.endpoint
    REGION      = "eu-west-2"
    LOG_LEVEL   = "INFO"
  }
}
```

### Lambda with layers and custom source path

```hcl
module "lambda_with_layers" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/lambda?ref=<tag>"

  service     = "bcss"
  project     = "etl"
  environment = "prod"
  name        = "transformer"

  handler_prefix       = "transform_data"
  function_description = "Transform data using shared utility layers"
  python_version       = "python3.12"
  source_path          = "${path.module}/../../lambdas/custom/transform_data/"
  timeout              = 120

  layers = [
    "arn:aws:lambda:eu-west-2:123456789012:layer:shared-utils:5",
    "arn:aws:lambda:eu-west-2:123456789012:layer:pandas:2"
  ]

  environment_variables = {
    BUCKET_NAME = module.s3.bucket_name
  }
}
```

## Conventions

- `handler_prefix` is required and determines the Lambda handler entry point (`<handler_prefix>.lambda_handler`).
- `function_description` is required for documentation and compliance.
- `python_version` defaults to `python3.11`; explicitly set it to pin runtime version.
- `source_path` defaults to `../../lambdas/<handler_prefix>/` relative to the module; override for custom layouts.
- `timeout` defaults to `3` seconds; increase for long-running functions.
- The module automatically attaches four AWS-managed IAM policies:
  - `AWSLambdaVPCAccessExecutionRole` (VPC networking)
  - `AWSLambdaBasicExecutionRole` (CloudWatch Logs)
  - `AmazonAPIGatewayPushToCloudWatchLogs` (API Gateway integration)
  - `AWSLambdaSQSQueueExecutionRole` (SQS polling)
- Use the `layers` input to attach Lambda layers; provide full ARNs including version.
- `vpc_subnet_ids` and `vpc_security_group_ids` are optional; omit for non-VPC functions.

## What this module does NOT do

- Create VPCs, subnets, or security groups; you must provide existing resource IDs.
- Package Lambda code; use the `source_path` to point to pre-packaged code or let the upstream module handle packaging.
- Create Lambda layers; you must create layers separately and provide ARNs.
- Configure Lambda event sources (SQS, EventBridge, S3, etc.); use native `aws_lambda_event_source_mapping` or trigger resources in consumer stacks.
- Manage Lambda function versions or aliases; use native `aws_lambda_alias` resources if needed.
- Provide custom IAM policies beyond the four AWS-managed policies; use the `iam` module to create custom policies and attach them separately.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_lambda_function"></a> [lambda\_function](#module\_lambda\_function) | terraform-aws-modules/lambda/aws | 8.8.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role_policy_attachment.lambda_to_cw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.push_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vpc_access_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Values to set in the Lambda function environment | `map(string)` | `{}` | no |
| <a name="input_function_description"></a> [function\_description](#input\_function\_description) | The description for the Lambda function | `string` | n/a | yes |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | The name of the Lambda function | `string` | `"uk-forwarder"` | no |
| <a name="input_handler_prefix"></a> [handler\_prefix](#input\_handler\_prefix) | The prefix for the Lambda handler function | `string` | n/a | yes |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_layers"></a> [layers](#input\_layers) | List of Lambda Layer ARNs to attach to the function | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | The Python version to use for the Lambda function | `string` | n/a | yes |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_source_path"></a> [source\_path](#input\_source\_path) | Optional override for the directory containing the Lambda's source code.<br/>Resolved relative to the root module (the stack) at plan/apply time.<br/><br/>When null (default), the module falls back to the historical layout<br/>`../../lambdas/<handler_prefix>/`, which expects sources under a top-level<br/>`infrastructure_v2/lambdas/` directory.<br/><br/>Set this to keep a stack's Lambda source co-located with the stack,<br/>e.g. source\_path = "lambdas/slack-notifier". | `string` | `null` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout for the Lambda function in seconds | `number` | `120` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security group IDs for the Lambda function | `list(string)` | `[]` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | List of VPC subnet IDs for the Lambda function | `list(string)` | `[]` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | Invoke ARN of the Lambda function. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Name of the Lambda function. |
| <a name="output_lambda_arn"></a> [lambda\_arn](#output\_lambda\_arn) | ARN of the Lambda function. |
| <a name="output_lambda_log_group_name"></a> [lambda\_log\_group\_name](#output\_lambda\_log\_group\_name) | CloudWatch Logs log group name for the Lambda function. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | IAM role name used by the Lambda function. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
