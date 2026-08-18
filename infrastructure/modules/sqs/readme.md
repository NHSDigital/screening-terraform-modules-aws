# SQS

Minimal NHS Screening wrapper for a standard SQS queue used for event delivery
workloads such as GitHub ARC `workflow_job` events. The module keeps the API
small, enables server-side encryption by default, and consumes the shared
`context.tf` for naming and tagging.

## What this module enforces

|Control|How it is enforced|
|---|---|
|Queue type|Creates a standard queue only; FIFO is intentionally excluded|
|Encryption at rest|Enables SQS-managed server-side encryption on the primary queue and optional DLQ|
|Transport security|Applies a queue policy that denies insecure transport|
|Publisher scope|Optional publisher statements are limited to `sqs:SendMessage` on this queue|
|Dead-letter queue|Optional DLQ is wired with the retry policy automatically|
|Tagging|Tags supported resources via `module.this.tags`|
|Creation gate|Resource creation is gated by `module.this.enabled`|

## Usage

### Minimal queue

```hcl
module "workflow_job_queue" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/sqs?ref=<tag>"

  enabled        = local.deploy_github_arc
  name           = "workflow-job-events"
  workspace      = terraform.workspace
  tags           = module.tags.tags
  labels_as_tags = []
}
```

### Queue with publisher permissions

```hcl
module "workflow_job_queue" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/sqs?ref=<tag>"

  enabled        = true
  name           = "workflow-job-events"
  workspace      = terraform.workspace
  tags           = module.tags.tags
  labels_as_tags = []

  publisher_statements = {
    eventbridge = {
      principals = {
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }
      source_arns = [aws_cloudwatch_event_rule.github_arc.arn]
    }
  }
}
```

### Queue with dead-letter queue and tuned settings

```hcl
module "workflow_job_queue" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/sqs?ref=<tag>"

  enabled                    = true
  name                       = "workflow-job-events"
  workspace                  = terraform.workspace
  tags                       = module.tags.tags
  labels_as_tags             = []
  visibility_timeout_seconds = 180
  message_retention_seconds  = 604800
  receive_wait_time_seconds  = 20

  dead_letter_queue = {
    create            = true
    max_receive_count = 3
  }
}
```

## Conventions

* `custom_name` is optional. When omitted, the queue name is derived from
  `module.this.id` so stacks can consume the module with the same ergonomics as
  other wrappers in this repository.
* Long polling defaults to `20` seconds to reduce empty receives for event-driven
  consumers.
* When `dead_letter_queue.create = true`, the DLQ name is derived automatically
  as `<queue-name>-dlq` and the retry policy is applied to the primary queue.
* Publisher policy statements are optional and constrained to `sqs:SendMessage`
  so the module stays generic without becoming a full IAM policy builder.

## What this module does NOT do

* Create FIFO queues or content-based duplicate-message suppression settings.
* Support arbitrary queue policy JSON or arbitrary IAM actions.
* Support custom KMS keys, SNS subscriptions, or EventBridge rules.
* Attach policies to the DLQ separately from the primary queue.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_sqs_queue.dead_letter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_iam_policy_document.queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_custom_name"></a> [custom\_name](#input\_custom\_name) | Optional explicit queue name. When null, the queue name is derived from module.this.id. | `string` | `null` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_dead_letter_queue"></a> [dead\_letter\_queue](#input\_dead\_letter\_queue) | Optional dead-letter queue configuration.<br/><br/>Defaults:<br/>- create: false<br/>- max\_receive\_count: 5<br/>- message\_retention\_seconds: 1209600 (14 days)<br/>- receive\_wait\_time\_seconds: 20<br/>- visibility\_timeout\_seconds: null (inherits primary queue visibility timeout) | <pre>object({<br/>    create                     = optional(bool, false)<br/>    max_receive_count          = optional(number, 5)<br/>    message_retention_seconds  = optional(number, 1209600)<br/>    receive_wait_time_seconds  = optional(number, 20)<br/>    visibility_timeout_seconds = optional(number)<br/>  })</pre> | `{}` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_message_retention_seconds"></a> [message\_retention\_seconds](#input\_message\_retention\_seconds) | Message retention period for the primary queue in seconds. | `number` | `345600` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_publisher_statements"></a> [publisher\_statements](#input\_publisher\_statements) | Optional queue policy statements that allow publishers to send messages.<br/>Each statement is constrained to `sqs:SendMessage` on this queue.<br/><br/>Example:<br/>  publisher\_statements = {<br/>    github\_events = {<br/>      principals = {<br/>        type        = "Service"<br/>        identifiers = ["events.amazonaws.com"]<br/>      }<br/>      source\_arns = ["arn:aws:events:eu-west-2:123456789012:rule/github-arc"]<br/>    }<br/>  } | <pre>map(object({<br/>    principals = object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })<br/>    source_arns     = optional(list(string), [])<br/>    source_accounts = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_receive_wait_time_seconds"></a> [receive\_wait\_time\_seconds](#input\_receive\_wait\_time\_seconds) | Receive wait time for long polling on the primary queue in seconds. | `number` | `20` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_visibility_timeout_seconds"></a> [visibility\_timeout\_seconds](#input\_visibility\_timeout\_seconds) | Visibility timeout for the primary queue in seconds. | `number` | `300` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dlq_arn"></a> [dlq\_arn](#output\_dlq\_arn) | The ARN of the dead-letter queue when created, otherwise null. |
| <a name="output_queue_arn"></a> [queue\_arn](#output\_queue\_arn) | The ARN of the primary queue. |
| <a name="output_queue_id"></a> [queue\_id](#output\_queue\_id) | The ID of the primary queue. For SQS this is the queue URL identifier. |
| <a name="output_queue_name"></a> [queue\_name](#output\_queue\_name) | The name of the primary queue. |
| <a name="output_queue_url"></a> [queue\_url](#output\_queue\_url) | The URL of the primary queue. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
