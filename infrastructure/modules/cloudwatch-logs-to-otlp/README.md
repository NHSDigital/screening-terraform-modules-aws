# CloudWatch Logs to OTLP

Composes screening Terraform wrappers to forward existing and future CloudWatch log groups through Firehose and a Lambda OTLP exporter.

## What this module enforces

| Control | Implementation |
| --- | --- |
| Private S3 retention | Existing S3 wrapper enforces encryption, TLS-only access, public access blocking, and versioning |
| Runtime credentials | Lambda receives Secrets Manager ARNs only and reads token values at runtime |
| Least-privilege delivery | IAM wrapper roles are scoped to the bucket, Firehose stream, forwarder, and configured secrets |
| Existing group coverage | CloudWatch log groups are discovered by prefix and use the subscription-filter wrapper |
| Future group coverage | Optional controller uses the EventBridge wrapper and a screened SQS queue for failed events |

## Usage

Store OTLP credentials with the existing Secrets Manager wrapper. Its write-only input keeps the token value out of Terraform state:

```hcl
module "otlp_auth" {
  source = "../../modules/secrets-manager"

  context                  = module.this.context
  name                     = "otel-auth-token"
  secret_string_wo         = var.otlp_auth_token
  secret_string_wo_version = var.otlp_auth_token_version
}
```

### Minimal

```hcl
module "logs_to_otlp" {
  source = "../../modules/cloudwatch-logs-to-otlp"

  context = module.this.context
  name    = "otel-logs"

  otlp_endpoint = "https://otel.example.gov:4317"
  otlp_auth_token_secret_arns = {
    default = module.otlp_auth.secret_arn
  }
  log_group_prefixes = ["/aws/lambda/my-service-"]
}
```

### Prefix-specific filters

```hcl
module "logs_to_otlp" {
  source = "../../modules/cloudwatch-logs-to-otlp"

  context = module.this.context
  name    = "otel-logs"

  otlp_endpoint = "https://otel.example.gov:4317"
  otlp_auth_token_secret_arns = { default = module.otlp_auth.secret_arn }
  log_group_prefixes = ["/aws/lambda/", "/aws/ecs/"]
  prefix_filter_patterns = {
    "/aws/lambda/" = "ERROR"
    "/aws/ecs/"    = "{ $.level = \"error\" }"
  }
  prefix_exclude_regexes = {
    "/aws/lambda/" = ["/canary$"]
  }
}
```

### Multiple runtime tokens and no future enrolment

```hcl
module "logs_to_otlp" {
  source = "../../modules/cloudwatch-logs-to-otlp"

  context = module.this.context
  name    = "otel-logs"

  otlp_endpoint = "https://otel.example.gov:4318"
  otlp_protocol = "http/protobuf"
  otlp_auth_token_secret_arns = {
    default = module.otlp_default_token.secret_arn
    urgent  = module.otlp_urgent_token.secret_arn
  }
  log_group_auth_token_map = { "^/aws/lambda/urgent-" = "urgent" }
  secret_kms_key_arns       = [module.otlp_secrets_kms.key_arn]
  log_group_prefixes        = ["/aws/lambda/"]
  subscribe_future_log_groups = false
  otel_attribute_auth_token_map = {
    "deployment.environment.name=.*-prod" = "urgent"
  }
}
```

Create the credentials with the `secrets-manager` wrapper and pass its `secret_arn` output. Do not pass `secret_string`; the forwarder retrieves each value at runtime. Attribute-based selectors are applied after log-group selectors and can override the selected token.

## Behaviour and constraints

- Existing log groups are discovered during Terraform planning. Apply again after creating groups if discovery occurred before the groups existed.
- Future enrolment is optional and requires CloudTrail management events for `CreateLogGroup` to reach EventBridge in the same Region.
- The EventBridge DLQ queue policy allows the EventBridge service principal from the current AWS account.
- Token Secrets Manager values are not read by Terraform. Supply secret ARNs and grant KMS decrypt ARNs when the secrets use customer-managed keys.
- Firehose buffers records before invoking the Lambda. OTLP delivery failures are retained in the S3 error prefix.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.72.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_existing_group_subscriptions"></a> [existing\_group\_subscriptions](#module\_existing\_group\_subscriptions) | ../cloudwatch-log-subscription-filter | n/a |
| <a name="module_failure_bucket"></a> [failure\_bucket](#module\_failure\_bucket) | ../s3-bucket | n/a |
| <a name="module_firehose"></a> [firehose](#module\_firehose) | ../firehose-extended-s3 | n/a |
| <a name="module_forwarder"></a> [forwarder](#module\_forwarder) | ../lambda | n/a |
| <a name="module_forwarder_logs"></a> [forwarder\_logs](#module\_forwarder\_logs) | ../cloudwatch-logs | n/a |
| <a name="module_future_group_subscriptions"></a> [future\_group\_subscriptions](#module\_future\_group\_subscriptions) | ../cloudwatch-log-subscription-controller | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ../iam | n/a |
| <a name="module_subscription_dlq"></a> [subscription\_dlq](#module\_subscription\_dlq) | ../sqs | n/a |
| <a name="module_this"></a> [this](#module\_this) | git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudwatch_log_groups.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudwatch_log_groups) | data source |
| [aws_iam_policy_document.firehose_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logs_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

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
| <a name="input_filter_pattern"></a> [filter\_pattern](#input\_filter\_pattern) | Default CloudWatch Logs filter pattern for prefixes without an explicit pattern. | `string` | `""` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Maximum OTLP forwarder execution time in seconds. | `number` | `120` | no |
| <a name="input_log_group_auth_token_map"></a> [log\_group\_auth\_token\_map](#input\_log\_group\_auth\_token\_map) | Optional map from log-group selector patterns to token names. | `map(string)` | `{}` | no |
| <a name="input_log_group_prefixes"></a> [log\_group\_prefixes](#input\_log\_group\_prefixes) | Non-empty list of log-group prefixes to subscribe, both for discovered existing groups and future groups. | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_otel_attribute_auth_token_map"></a> [otel\_attribute\_auth\_token\_map](#input\_otel\_attribute\_auth\_token\_map) | Optional map from resource-attribute selectors to token names. | `map(string)` | `{}` | no |
| <a name="input_otel_resource_attributes"></a> [otel\_resource\_attributes](#input\_otel\_resource\_attributes) | Comma-separated OpenTelemetry resource attributes applied to forwarded log records. | `string` | `""` | no |
| <a name="input_otlp_auth_token_secret_arns"></a> [otlp\_auth\_token\_secret\_arns](#input\_otlp\_auth\_token\_secret\_arns) | Map of token names to Secrets Manager secret ARNs. Values are fetched at Lambda runtime and cached; the default token name is required. | `map(string)` | n/a | yes |
| <a name="input_otlp_endpoint"></a> [otlp\_endpoint](#input\_otlp\_endpoint) | OTLP collector endpoint, including scheme and port. | `string` | n/a | yes |
| <a name="input_otlp_protocol"></a> [otlp\_protocol](#input\_otlp\_protocol) | OTLP transport protocol used by the forwarder. | `string` | `"grpc"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_prefix_exclude_regexes"></a> [prefix\_exclude\_regexes](#input\_prefix\_exclude\_regexes) | Optional regular expressions keyed by prefix to exclude matching log-group names. | `map(list(string))` | `{}` | no |
| <a name="input_prefix_filter_patterns"></a> [prefix\_filter\_patterns](#input\_prefix\_filter\_patterns) | Optional CloudWatch Logs filter patterns keyed by prefix; the longest matching prefix wins. | `map(string)` | `{}` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | Python runtime used by the forwarder and subscription controller. | `string` | `"python3.12"` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_s3_prefix"></a> [s3\_prefix](#input\_s3\_prefix) | Prefix for Firehose records retained in the private S3 destination. | `string` | `"failed-records/"` | no |
| <a name="input_secret_kms_key_arns"></a> [secret\_kms\_key\_arns](#input\_secret\_kms\_key\_arns) | Optional KMS key ARNs used to encrypt the configured Secrets Manager secrets. | `list(string)` | `[]` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_subscribe_future_log_groups"></a> [subscribe\_future\_log\_groups](#input\_subscribe\_future\_log\_groups) | Whether to enrol future matching log groups through CloudTrail and EventBridge. | `bool` | `true` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_existing_subscription_filter_names"></a> [existing\_subscription\_filter\_names](#output\_existing\_subscription\_filter\_names) | Map of discovered log-group names to their subscription-filter names. |
| <a name="output_failure_bucket_arn"></a> [failure\_bucket\_arn](#output\_failure\_bucket\_arn) | ARN of the private S3 bucket used by Firehose for retained and failed records. |
| <a name="output_firehose_arn"></a> [firehose\_arn](#output\_firehose\_arn) | ARN of the CloudWatch Logs Firehose delivery stream. |
| <a name="output_forwarder_lambda_arn"></a> [forwarder\_lambda\_arn](#output\_forwarder\_lambda\_arn) | ARN of the OTLP forwarder Lambda. |
| <a name="output_future_subscription_event_rule_arn"></a> [future\_subscription\_event\_rule\_arn](#output\_future\_subscription\_event\_rule\_arn) | ARN of the EventBridge rule used for future log groups, or null when future enrolment is disabled. |
| <a name="output_subscription_dlq_arn"></a> [subscription\_dlq\_arn](#output\_subscription\_dlq\_arn) | ARN of the SQS queue used for EventBridge subscription-controller failures. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
