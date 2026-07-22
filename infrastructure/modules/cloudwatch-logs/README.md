# CloudWatch Logs

NHS Screening wrapper around the [terraform-aws-modules/CloudWatch/aws](https://registry.terraform.io/modules/terraform-aws-modules/cloudwatch/aws) `log-group` and `log-stream` submodules that enforces screening platform baseline controls.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| Log group | Always created when `module.this.enabled = true`; logging is mandatory by design |
| Naming convention | Log group name derived from context; when `delimiter = "/"`, names are path-style with leading `/` (e.g., `/<service>/<project>/<environment>/<stack>/<name>`); forward slashes preserved |
| Encryption at rest | Always enabled; AWS-managed encryption by default, or customer-managed KMS when `kms_key_id` is provided |
| Retention policy | Configurable; defaults to 30 days; only AWS-approved retention values accepted |
| Stream management | Optional; streams only created when `stream_names` is non-empty; use `for_each` for stable iteration |
| Tagging | All NHS-required tags applied automatically via `module.this.tags` |
| Data protection | Optional `skip_destroy` to prevent accidental log group deletion during terraform destroy |
| Log class | Optional cost optimization via `log_group_class`; choose INFREQUENT_ACCESS for archival logging |
| Creation gate | All resources gated by `module.this.enabled` |

## Usage

### Minimal: log group only (recommended for ECS/Lambda auto-managed streams)

```hcl
module "app_logs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cloudwatch-logs?ref=<tag>"

  context = module.this.context

  # Creates log group at /<service>/<project>/<environment>/<stack>/<name>
  # 30-day retention (default)
  # AWS-managed encryption
  # No streams created
}

# Pass to ECS service or Lambda function
output "ecs_log_group" {
  value = module.app_logs.cloudwatch_log_group_name
}
```

### With customer-managed KMS encryption and longer retention

```hcl
module "audit_logs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cloudwatch-logs?ref=<tag>"

  context = module.this.context

  retention_in_days = 90              # 90-day retention for compliance
  kms_key_id        = module.kms.key_arn  # Customer-managed encryption for sensitive logs
}
```

### With multiple named streams

```hcl
module "worker_logs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cloudwatch-logs?ref=<tag>"

  context = module.this.context

  retention_in_days = 30
  stream_names      = ["background-jobs", "scheduled-tasks", "webhooks"]

  # Access individual streams by name
  # output "background_jobs_arn" { value = module.worker_logs.cloudwatch_log_stream_arns["background-jobs"] }
}
```

### With infrequent-access log class for cost optimization

```hcl
module "archive_logs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cloudwatch-logs?ref=<tag>"

  context = module.this.context

  retention_in_days = 180                      # Long retention for archival
  log_group_class   = "INFREQUENT_ACCESS"     # Lower cost for infrequently accessed logs
  skip_destroy      = true                     # Protect from accidental deletion
}
```

### Path-style naming with `delimiter = "/"`

When you set `delimiter = "/"`, log group names include a leading `/` and use `/` throughout:

```hcl
module "path_style_logs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cloudwatch-logs?ref=<tag>"

  context   = module.this.context
  delimiter = "/"  # Path-style naming
  stack     = "api"
  name      = "events"

  retention_in_days = 30
}

# Results in log group name: /bcss/screening/prod/api/events
# (assuming context: service=bcss, project=screening, environment=prod)
```

### Standard naming (default delimiter: `-`)

Without explicit `delimiter`, log group names use the default hyphen separator:

```hcl
module "standard_logs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cloudwatch-logs?ref=<tag>"

  context = module.this.context
  # delimiter not set — uses default "-"
  stack   = "api"
  name    = "events"

  retention_in_days = 30
}

# Results in log group name: bcss-screening-prod-api-events
# (no leading /)
```

## Conventions

### Naming

- **Log group name**: Derived from context labels (`<service>/<project>/<environment>/<stack>/<name>`). When `delimiter = "/"`, names are path-style with a leading `/` (e.g., `/bcss/website/prod/api/events`). When using the default delimiter, names are hyphen-separated without a leading `/` (e.g., `bcss-website-prod-api-events`).
  - Forward slashes are preserved in context-derived names when `delimiter = "/"`.
  - Override with `log_group_name` variable if custom naming is needed.
- **Stream names**: Each stream name in `stream_names` becomes a separate CloudWatch log stream within the group.
  - Valid characters: alphanumeric, `.`, `-`, `_`, `/`, `#`.
  - Example: `stream_names = ["application", "error", "audit"]` creates 3 streams.

### Retention & Cost

- **Retention**: Defaults to 30 days; adjust based on compliance/audit requirements.
  - Valid values (AWS-only): 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653.
- **Log class**: Use `INFREQUENT_ACCESS` for logs accessed rarely; saves ~80% on storage vs STANDARD.
  - Only economical with retention > 30 days.
  - Precondition validates this recommendation.

### Encryption & Data Protection

- **Encryption**: Always enabled (baseline control).
  - AWS-managed (default): no action required; KMS is handled by AWS.
  - Customer-managed (recommended for sensitive logs): provide `kms_key_id` = KMS key ARN.
- **Skip destroy**: Set `skip_destroy = true` to prevent accidental deletion of log groups during `terraform destroy`.
  - Recommended for audit/compliance logs.
  - Log group remains in AWS but removed from Terraform state; requires manual deletion.

### Stream Management

- **Streams are optional**: Empty `stream_names` creates log group only (recommended for Lambda/ECS auto-managed streams).
- **Streams use `for_each`**: Adding/removing streams from `stream_names` only affects the named streams, not others.
  - Example: changing `["stream1", "stream2", "stream3"]` to `["stream1", "stream3", "stream4"]` destroys only stream2, creates stream4.

### Disabling Resources

- Set `enabled = false` (via context) to skip all log group and stream creation.
  - Useful for feature flags or environment-specific deployments.

## Validation & Security Constraints

The module enforces cross-variable validation rules via `validations.tf` preconditions:

| Constraint | Condition | Reason |
| --- | --- | --- |
| **INFREQUENT_ACCESS requires long retention** | If `log_group_class = "INFREQUENT_ACCESS"`, then `retention_in_days > 30` | INFREQUENT_ACCESS only saves money (~80%) if logs are archived long-term; short retention defeats the cost benefit |
| **skip_destroy requires reasonable retention** | If `skip_destroy = true`, then `retention_in_days >= 30` | Data protection intent (skip_destroy) conflicts with very short retention; misconfiguration suggests data loss risk |
| **Log group name must follow convention** | If `log_group_name` is provided, it must start with `/` | Ensures consistent NHS naming pattern across all logs (e.g., `/<service>/<project>/<environment>/<stack>/<name>`) |

These preconditions run before resource creation and fail fast if misconfigured, preventing deployment of inefficient or risky patterns.

## What this module does NOT do

- **Does not create metric filters** — Use the `terraform-aws-modules/cloudwatch/aws//modules/log-metric-filter` submodule to create filters, detect patterns, and trigger metric alarms.
- **Does not create subscription filters** — Use `aws_cloudwatch_log_subscription_filter` to route logs to Kinesis, Lambda, S3 via Firehose, or other destinations.
- **Does not manage log destinations** — Use `aws_cloudwatch_log_destination` and policies if centralizing logs from multiple accounts or services.
- **Does not manage resource-based policies** — Log group resource policies must be created separately if granting cross-account/cross-service access.
- **Does not create alarms or dashboards** — Use `terraform-aws-modules/cloudwatch/aws//modules/metric-alarm` to create alarms based on log metrics or direct metrics.
- **Does not configure log data protection** — Use the `log-data-protection-policy` submodule to redact sensitive data (PII, credentials) from logs.
- **Does not manage log insights queries** — Use the `query-definition` submodule or AWS Console to create reusable CloudWatch Logs Insights queries.
- **Does not auto-create streams for Lambda/ECS** — Lambda and ECS create streams automatically when first logs arrive; do not pre-create streams for them with this module.

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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | terraform-aws-modules/cloudwatch/aws//modules/log-group | 5.7.2 |
| <a name="module_log_group_label"></a> [log\_group\_label](#module\_log\_group\_label) | ../tags | n/a |
| <a name="module_log_stream"></a> [log\_stream](#module\_log\_stream) | terraform-aws-modules/cloudwatch/aws//modules/log-stream | 5.7.2 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

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
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Optional customer-managed KMS key ARN for CloudWatch log group encryption.<br/><br/>When null, CloudWatch Logs uses AWS-managed encryption.<br/><br/>Encryption at rest remains enabled either way.<br/><br/>Please note, after the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group.<br/><br/>All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested. | `string` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_log_group_class"></a> [log\_group\_class](#input\_log\_group\_class) | Specified the log class of the log group. Valid values are 'STANDARD' or 'INFREQUENT\_ACCESS'. When null, defaults to STANDARD. Use INFREQUENT\_ACCESS for lower-cost archival of logs accessed infrequently. | `string` | `null` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | Name of the CloudWatch log group. Defaults to `/<service>/<project>/<environment>/<stack>/<name>` derived from context. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | CloudWatch log group retention in days. Valid values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653. | `number` | `30` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_skip_destroy"></a> [skip\_destroy](#input\_skip\_destroy) | When true, CloudWatch log group is removed from Terraform state but not deleted at destroy time. Prevents accidental deletion of log groups containing critical audit/compliance data. When null, log group is deleted with the module. | `bool` | `null` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_stream_names"></a> [stream\_names](#input\_stream\_names) | Names of CloudWatch log streams to create within the log group. Empty list creates log group only (recommended for Lambda/ECS auto-managed streams). | `list(string)` | `[]` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to this module path. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group. |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group. |
| <a name="output_cloudwatch_log_stream_arns"></a> [cloudwatch\_log\_stream\_arns](#output\_cloudwatch\_log\_stream\_arns) | Map of CloudWatch log stream ARNs, keyed by stream name. |
| <a name="output_cloudwatch_log_stream_names"></a> [cloudwatch\_log\_stream\_names](#output\_cloudwatch\_log\_stream\_names) | Map of CloudWatch log stream names, keyed by stream name. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
