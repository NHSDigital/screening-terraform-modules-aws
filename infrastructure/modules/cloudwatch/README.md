# CloudWatch

NHS Screening wrapper around selected submodules from the
[terraform-aws-modules CloudWatch module](https://registry.terraform.io/modules/terraform-aws-modules/cloudwatch/aws/latest)
that provides a single module entry point for common CloudWatch log and alarm building blocks.

## Included submodules

- `log-group`
- `log-stream`
- `log-metric-filter`
- `metric-alarm`
- `metric-alarms-by-multiple-dimensions`

## What this module enforces

| Control | How it is enforced |
| ------- | ------------------ |
| Single entry point | One shared wrapper exposes the requested CloudWatch submodules together |
| Creation gate | Each submodule is gated by `module.this.enabled` and a non-null config object |
| Naming | Names are derived from `module.this.id` |
| Tagging | Log groups and alarms that support tags receive `module.this.tags` |
| Minimal interface | Only the minimal required or functionally necessary configuration is exposed |

## Usage

### Complete example

```hcl
module "cloudwatch" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cloudwatch?ref=main"

  service     = "bcss"
  project     = "shared-resources"
  environment = "prod"
  stack       = "monitoring"
  name        = "application"

  log_group = {}

  log_stream = {}

  log_metric_filter = {
    pattern                         = "ERROR"
    metric_transformation_name      = "ErrorCount"
    metric_transformation_namespace = "BCSS/Application"
  }

  metric_alarm = {
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    threshold           = 10
  }

  metric_alarms_by_multiple_dimensions = {
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    threshold           = 10
    dimensions = {
      lambda1 = {
        FunctionName = "function-one"
      }
      lambda2 = {
        FunctionName = "function-two"
      }
    }
  }
}
```

## Conventions

- Set a submodule object to `null` to skip creating that submodule.
- `log_stream` and `log_metric_filter` depend on `log_group` being configured in the same module call.
- `metric_alarm` and `metric_alarms_by_multiple_dimensions` derive their metric name and namespace from `log_metric_filter`.
- `metric_alarm` uses fixed defaults of `period = "60"` and `statistic = "Sum"`.
- `metric_alarms_by_multiple_dimensions` uses fixed defaults of `period = "60"` and `statistic = "Sum"`.
- CloudWatch log streams and log metric filters do not support tags directly, so only the submodules that accept tags receive `module.this.tags`.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | terraform-aws-modules/cloudwatch/aws//modules/log-group | 5.7.2 |
| <a name="module_log_metric_filter"></a> [log\_metric\_filter](#module\_log\_metric\_filter) | terraform-aws-modules/cloudwatch/aws//modules/log-metric-filter | 5.7.2 |
| <a name="module_log_stream"></a> [log\_stream](#module\_log\_stream) | terraform-aws-modules/cloudwatch/aws//modules/log-stream | 5.7.2 |
| <a name="module_metric_alarm"></a> [metric\_alarm](#module\_metric\_alarm) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 5.7.2 |
| <a name="module_metric_alarms_by_multiple_dimensions"></a> [metric\_alarms\_by\_multiple\_dimensions](#module\_metric\_alarms\_by\_multiple\_dimensions) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarms-by-multiple-dimensions | 5.7.2 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

No resources.

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
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_log_group"></a> [log\_group](#input\_log\_group) | Configuration for the CloudWatch log group submodule. Set to null to skip creating a log group. | `object({})` | `null` | no |
| <a name="input_log_metric_filter"></a> [log\_metric\_filter](#input\_log\_metric\_filter) | Configuration for the CloudWatch log metric filter submodule. Set to null to skip creating a log metric filter. | <pre>object({<br/>    pattern                         = string<br/>    metric_transformation_name      = string<br/>    metric_transformation_namespace = string<br/>  })</pre> | `null` | no |
| <a name="input_log_stream"></a> [log\_stream](#input\_log\_stream) | Configuration for the CloudWatch log stream submodule. Set to null to skip creating a log stream. | `object({})` | `null` | no |
| <a name="input_metric_alarm"></a> [metric\_alarm](#input\_metric\_alarm) | Configuration for the CloudWatch metric alarm submodule. Set to null to skip creating a metric alarm. | <pre>object({<br/>    comparison_operator = string<br/>    evaluation_periods  = number<br/>    threshold           = number<br/>  })</pre> | `null` | no |
| <a name="input_metric_alarms_by_multiple_dimensions"></a> [metric\_alarms\_by\_multiple\_dimensions](#input\_metric\_alarms\_by\_multiple\_dimensions) | Configuration for the CloudWatch metric alarms by multiple dimensions submodule. Set to null to skip creating these alarms. | <pre>object({<br/>    comparison_operator = string<br/>    evaluation_periods  = number<br/>    threshold           = number<br/>    dimensions          = map(map(string))<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to this module path. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group, if created. |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group, if created. |
| <a name="output_cloudwatch_log_metric_filter_id"></a> [cloudwatch\_log\_metric\_filter\_id](#output\_cloudwatch\_log\_metric\_filter\_id) | The name of the CloudWatch log metric filter, if created. |
| <a name="output_cloudwatch_log_stream_arn"></a> [cloudwatch\_log\_stream\_arn](#output\_cloudwatch\_log\_stream\_arn) | ARN of the CloudWatch log stream, if created. |
| <a name="output_cloudwatch_log_stream_name"></a> [cloudwatch\_log\_stream\_name](#output\_cloudwatch\_log\_stream\_name) | Name of the CloudWatch log stream, if created. |
| <a name="output_cloudwatch_metric_alarm_arn"></a> [cloudwatch\_metric\_alarm\_arn](#output\_cloudwatch\_metric\_alarm\_arn) | The ARN of the CloudWatch metric alarm, if created. |
| <a name="output_cloudwatch_metric_alarm_arns"></a> [cloudwatch\_metric\_alarm\_arns](#output\_cloudwatch\_metric\_alarm\_arns) | Map of CloudWatch metric alarm ARNs created by the multiple-dimensions submodule, if configured. |
| <a name="output_cloudwatch_metric_alarm_id"></a> [cloudwatch\_metric\_alarm\_id](#output\_cloudwatch\_metric\_alarm\_id) | The ID of the CloudWatch metric alarm, if created. |
| <a name="output_cloudwatch_metric_alarm_ids"></a> [cloudwatch\_metric\_alarm\_ids](#output\_cloudwatch\_metric\_alarm\_ids) | Map of CloudWatch metric alarm IDs created by the multiple-dimensions submodule, if configured. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
