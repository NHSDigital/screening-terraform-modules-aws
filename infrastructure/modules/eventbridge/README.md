# EventBridge

NHS Screening wrapper around the community
[`terraform-aws-modules/terraform-aws-eventbridge`](https://registry.terraform.io/modules/terraform-aws-modules/eventbridge/aws/4.3.2)
module that consumes the shared `context.tf` for naming and tagging.

DAVEH

DAVEH: document var.bus_name

----

DAVEH: document var.log_delivery

DAVEH: document var.connections

DAVEH: document var.api_destinations

DAVEH: document var.schedule_groups

DAVEH: document var.pipes

----

DAVEH: document var.kms_key_identifier

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
| <a name="module_eventbridge"></a> [eventbridge](#module\_eventbridge) | git::https://github.com/terraform-aws-modules/terraform-aws-eventbridge.git | f9934726324c988f823682884b4fa003586a7b6f |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_api_destinations"></a> [api\_destinations](#input\_api\_destinations) | A map of objects with EventBridge Destination definitions. | `map(any)` | `{}` | no |
| <a name="input_append_connection_postfix"></a> [append\_connection\_postfix](#input\_append\_connection\_postfix) | Controls whether to append '-connection' to the name of the connection | `bool` | `true` | no |
| <a name="input_append_destination_postfix"></a> [append\_destination\_postfix](#input\_append\_destination\_postfix) | Controls whether to append '-destination' to the name of the destination | `bool` | `true` | no |
| <a name="input_append_pipe_postfix"></a> [append\_pipe\_postfix](#input\_append\_pipe\_postfix) | Controls whether to append '-pipe' to the name of the pipe | `bool` | `true` | no |
| <a name="input_append_rule_postfix"></a> [append\_rule\_postfix](#input\_append\_rule\_postfix) | Controls whether to append '-rule' to the name of the rule | `bool` | `true` | no |
| <a name="input_append_schedule_group_postfix"></a> [append\_schedule\_group\_postfix](#input\_append\_schedule\_group\_postfix) | Controls whether to append '-group' to the name of the schedule group | `bool` | `true` | no |
| <a name="input_append_schedule_postfix"></a> [append\_schedule\_postfix](#input\_append\_schedule\_postfix) | Controls whether to append '-schedule' to the name of the schedule | `bool` | `true` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_archives"></a> [archives](#input\_archives) | A map of objects with the EventBridge Archive definitions. | `map(any)` | `{}` | no |
| <a name="input_attach_api_destination_policy"></a> [attach\_api\_destination\_policy](#input\_attach\_api\_destination\_policy) | Controls whether the API Destination policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_cloudwatch_policy"></a> [attach\_cloudwatch\_policy](#input\_attach\_cloudwatch\_policy) | Controls whether the Cloudwatch policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_ecs_policy"></a> [attach\_ecs\_policy](#input\_attach\_ecs\_policy) | Controls whether the ECS policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_kinesis_firehose_policy"></a> [attach\_kinesis\_firehose\_policy](#input\_attach\_kinesis\_firehose\_policy) | Controls whether the Kinesis Firehose policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_kinesis_policy"></a> [attach\_kinesis\_policy](#input\_attach\_kinesis\_policy) | Controls whether the Kinesis policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_lambda_policy"></a> [attach\_lambda\_policy](#input\_attach\_lambda\_policy) | Controls whether the Lambda Function policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_policies"></a> [attach\_policies](#input\_attach\_policies) | Controls whether list of policies should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy"></a> [attach\_policy](#input\_attach\_policy) | Controls whether policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_json"></a> [attach\_policy\_json](#input\_attach\_policy\_json) | Controls whether policy\_json should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_jsons"></a> [attach\_policy\_jsons](#input\_attach\_policy\_jsons) | Controls whether policy\_jsons should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_statements"></a> [attach\_policy\_statements](#input\_attach\_policy\_statements) | Controls whether policy\_statements should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_sfn_policy"></a> [attach\_sfn\_policy](#input\_attach\_sfn\_policy) | Controls whether the StepFunction policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_sns_policy"></a> [attach\_sns\_policy](#input\_attach\_sns\_policy) | Controls whether the SNS policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_sqs_policy"></a> [attach\_sqs\_policy](#input\_attach\_sqs\_policy) | Controls whether the SQS policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_tracing_policy"></a> [attach\_tracing\_policy](#input\_attach\_tracing\_policy) | Controls whether X-Ray tracing policy should be added to IAM role for EventBridge | `bool` | `false` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_bus_description"></a> [bus\_description](#input\_bus\_description) | Event bus description | `string` | `null` | no |
| <a name="input_bus_name"></a> [bus\_name](#input\_bus\_name) | A unique name for your EventBridge Bus. Must be unique per AWS account and region. Defaults to whatever the tags module produces | `string` | `null` | no |
| <a name="input_cloudwatch_target_arns"></a> [cloudwatch\_target\_arns](#input\_cloudwatch\_target\_arns) | The Amazon Resource Name (ARN) of the Cloudwatch Log Streams you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_connections"></a> [connections](#input\_connections) | A map of objects with EventBridge Connection definitions. | `any` | `{}` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_create_api_destinations"></a> [create\_api\_destinations](#input\_create\_api\_destinations) | Controls whether EventBridge Destination resources should be created | `bool` | `false` | no |
| <a name="input_create_archives"></a> [create\_archives](#input\_create\_archives) | Controls whether EventBridge Archive resources should be created | `bool` | `false` | no |
| <a name="input_create_bus"></a> [create\_bus](#input\_create\_bus) | Controls whether EventBridge Bus resource should be created | `bool` | `true` | no |
| <a name="input_create_connections"></a> [create\_connections](#input\_create\_connections) | Controls whether EventBridge Connection resources should be created | `bool` | `false` | no |
| <a name="input_create_log_delivery"></a> [create\_log\_delivery](#input\_create\_log\_delivery) | Controls whether EventBridge log delivery resources should be created | `bool` | `true` | no |
| <a name="input_create_log_delivery_source"></a> [create\_log\_delivery\_source](#input\_create\_log\_delivery\_source) | Controls whether EventBridge log delivery source resource should be created | `bool` | `true` | no |
| <a name="input_create_permissions"></a> [create\_permissions](#input\_create\_permissions) | Controls whether EventBridge Permission resources should be created | `bool` | `true` | no |
| <a name="input_create_pipe_role_only"></a> [create\_pipe\_role\_only](#input\_create\_pipe\_role\_only) | Controls whether an IAM role should be created for the pipes only | `bool` | `false` | no |
| <a name="input_create_pipes"></a> [create\_pipes](#input\_create\_pipes) | Controls whether EventBridge Pipes resources should be created | `bool` | `true` | no |
| <a name="input_create_role"></a> [create\_role](#input\_create\_role) | Controls whether IAM roles should be created | `bool` | `true` | no |
| <a name="input_create_rules"></a> [create\_rules](#input\_create\_rules) | Controls whether EventBridge Rule resources should be created | `bool` | `true` | no |
| <a name="input_create_schedule_groups"></a> [create\_schedule\_groups](#input\_create\_schedule\_groups) | Controls whether EventBridge Schedule Group resources should be created | `bool` | `true` | no |
| <a name="input_create_schedules"></a> [create\_schedules](#input\_create\_schedules) | Controls whether EventBridge Schedule resources should be created | `bool` | `true` | no |
| <a name="input_create_schemas_discoverer"></a> [create\_schemas\_discoverer](#input\_create\_schemas\_discoverer) | Controls whether default schemas discoverer should be created | `bool` | `false` | no |
| <a name="input_create_targets"></a> [create\_targets](#input\_create\_targets) | Controls whether EventBridge Target resources should be created | `bool` | `true` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_dead_letter_config"></a> [dead\_letter\_config](#input\_dead\_letter\_config) | Configuration details of the Amazon SQS queue for EventBridge to use as a dead-letter queue (DLQ) | `any` | `{}` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_ecs_pass_role_resources"></a> [ecs\_pass\_role\_resources](#input\_ecs\_pass\_role\_resources) | List of approved roles to be passed | `list(string)` | `[]` | no |
| <a name="input_ecs_target_arns"></a> [ecs\_target\_arns](#input\_ecs\_target\_arns) | The Amazon Resource Name (ARN) of the AWS ECS Tasks you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_event_source_name"></a> [event\_source\_name](#input\_event\_source\_name) | The partner event source that the new event bus will be matched with. Must match name. | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_kinesis_firehose_target_arns"></a> [kinesis\_firehose\_target\_arns](#input\_kinesis\_firehose\_target\_arns) | The Amazon Resource Name (ARN) of the Kinesis Firehose Delivery Streams you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_kinesis_target_arns"></a> [kinesis\_target\_arns](#input\_kinesis\_target\_arns) | The Amazon Resource Name (ARN) of the Kinesis Streams you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_kms_key_identifier"></a> [kms\_key\_identifier](#input\_kms\_key\_identifier) | The identifier of the AWS KMS customer managed key for EventBridge to use, to encrypt events on this event bus. The identifier can be the key Amazon Resource Name (ARN), KeyId, key alias, or key alias ARN. | `string` | n/a | yes |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_lambda_target_arns"></a> [lambda\_target\_arns](#input\_lambda\_target\_arns) | The Amazon Resource Name (ARN) of the Lambda Functions you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_log_config"></a> [log\_config](#input\_log\_config) | The configuration block for the EventBridge bus log config settings | <pre>object({<br/>    include_detail = string<br/>    level          = string<br/>  })</pre> | `null` | no |
| <a name="input_log_delivery"></a> [log\_delivery](#input\_log\_delivery) | Map of the configuration block for the EventBridge bus log delivery settings (key is the type of log delivery: cloudwatch\_logs, s3, firehose) | <pre>map(object({<br/>    enabled         = optional(bool, true)<br/>    destination_arn = string<br/>    source_name     = optional(string)<br/>    name            = optional(string)<br/>    output_format   = optional(string)<br/>    field_delimiter = optional(string)<br/>    record_fields   = optional(list(string))<br/>    s3_delivery_configuration = optional(object({<br/>      enable_hive_compatible_path = optional(bool)<br/>      suffix_path                 = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_log_delivery_source_name"></a> [log\_delivery\_source\_name](#input\_log\_delivery\_source\_name) | Name of log delivery source; defaults to the name we use for the bus | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_number_of_policies"></a> [number\_of\_policies](#input\_number\_of\_policies) | Number of policies to attach to IAM role | `number` | `0` | no |
| <a name="input_number_of_policy_jsons"></a> [number\_of\_policy\_jsons](#input\_number\_of\_policy\_jsons) | Number of policies JSON to attach to IAM role | `number` | `0` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_permissions"></a> [permissions](#input\_permissions) | A map of objects with EventBridge Permission definitions. | `map(any)` | `{}` | no |
| <a name="input_pipes"></a> [pipes](#input\_pipes) | A map of objects with EventBridge Pipe definitions. | `any` | `{}` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | List of policy statements ARN to attach to IAM role | `list(string)` | `[]` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | An additional policy document ARN to attach to IAM role | `string` | `null` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | An additional policy document as JSON to attach to IAM role | `string` | `null` | no |
| <a name="input_policy_jsons"></a> [policy\_jsons](#input\_policy\_jsons) | List of additional policy documents as JSON to attach to IAM role | `list(string)` | `[]` | no |
| <a name="input_policy_path"></a> [policy\_path](#input\_policy\_path) | Path of IAM policy to use for EventBridge | `string` | `null` | no |
| <a name="input_policy_statements"></a> [policy\_statements](#input\_policy\_statements) | Map of dynamic policy statements to attach to IAM role | `any` | `{}` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Description of IAM role to use for EventBridge | `string` | `null` | no |
| <a name="input_role_force_detach_policies"></a> [role\_force\_detach\_policies](#input\_role\_force\_detach\_policies) | Specifies to force detaching any policies the IAM role has before destroying it. | `bool` | `true` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of IAM role to use for EventBridge | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | Path of IAM role to use for EventBridge | `string` | `null` | no |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | The ARN of the policy that is used to set the permissions boundary for the IAM role used by EventBridge | `string` | `null` | no |
| <a name="input_role_tags"></a> [role\_tags](#input\_role\_tags) | A map of tags to assign to IAM role | `map(string)` | `{}` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | A map of objects with EventBridge Rule definitions. | `map(any)` | `{}` | no |
| <a name="input_schedule_group_timeouts"></a> [schedule\_group\_timeouts](#input\_schedule\_group\_timeouts) | A map of objects with EventBridge Schedule Group create and delete timeouts. | `map(string)` | `{}` | no |
| <a name="input_schedule_groups"></a> [schedule\_groups](#input\_schedule\_groups) | A map of objects with EventBridge Schedule Group definitions. | `any` | `{}` | no |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | A map of objects with EventBridge Schedule definitions. | `map(any)` | `{}` | no |
| <a name="input_schemas_discoverer_description"></a> [schemas\_discoverer\_description](#input\_schemas\_discoverer\_description) | Default schemas discoverer description | `string` | `"Auto schemas discoverer event"` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_sfn_target_arns"></a> [sfn\_target\_arns](#input\_sfn\_target\_arns) | The Amazon Resource Name (ARN) of the StepFunctions you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_sns_kms_arns"></a> [sns\_kms\_arns](#input\_sns\_kms\_arns) | The Amazon Resource Name (ARN) of the AWS KMS's configured for AWS SNS you want Decrypt/GenerateDataKey for | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_sns_target_arns"></a> [sns\_target\_arns](#input\_sns\_target\_arns) | The Amazon Resource Name (ARN) of the AWS SNS's you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_sqs_target_arns"></a> [sqs\_target\_arns](#input\_sqs\_target\_arns) | The Amazon Resource Name (ARN) of the AWS SQS Queues you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_targets"></a> [targets](#input\_targets) | A map of objects with EventBridge Target definitions. | `any` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_trusted_entities"></a> [trusted\_entities](#input\_trusted\_entities) | Additional trusted entities for assuming roles (trust relationship) | `list(string)` | `[]` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_eventbridge_api_destination_arns"></a> [eventbridge\_api\_destination\_arns](#output\_eventbridge\_api\_destination\_arns) | The EventBridge API Destination ARNs |
| <a name="output_eventbridge_api_destinations"></a> [eventbridge\_api\_destinations](#output\_eventbridge\_api\_destinations) | The EventBridge API Destinations created and their attributes |
| <a name="output_eventbridge_archive_arns"></a> [eventbridge\_archive\_arns](#output\_eventbridge\_archive\_arns) | The EventBridge Archive ARNs |
| <a name="output_eventbridge_archives"></a> [eventbridge\_archives](#output\_eventbridge\_archives) | The EventBridge Archives created and their attributes |
| <a name="output_eventbridge_bus"></a> [eventbridge\_bus](#output\_eventbridge\_bus) | The EventBridge Bus created and their attributes |
| <a name="output_eventbridge_bus_arn"></a> [eventbridge\_bus\_arn](#output\_eventbridge\_bus\_arn) | The EventBridge Bus ARN |
| <a name="output_eventbridge_bus_name"></a> [eventbridge\_bus\_name](#output\_eventbridge\_bus\_name) | The EventBridge Bus Name |
| <a name="output_eventbridge_connection_arns"></a> [eventbridge\_connection\_arns](#output\_eventbridge\_connection\_arns) | The EventBridge Connection Arns |
| <a name="output_eventbridge_connection_ids"></a> [eventbridge\_connection\_ids](#output\_eventbridge\_connection\_ids) | The EventBridge Connection IDs |
| <a name="output_eventbridge_connections"></a> [eventbridge\_connections](#output\_eventbridge\_connections) | The EventBridge Connections created and their attributes |
| <a name="output_eventbridge_iam_roles"></a> [eventbridge\_iam\_roles](#output\_eventbridge\_iam\_roles) | The EventBridge IAM roles created and their attributes |
| <a name="output_eventbridge_log_delivery_source_arn"></a> [eventbridge\_log\_delivery\_source\_arn](#output\_eventbridge\_log\_delivery\_source\_arn) | The EventBridge Bus CloudWatch Log Delivery Source ARN |
| <a name="output_eventbridge_log_delivery_source_name"></a> [eventbridge\_log\_delivery\_source\_name](#output\_eventbridge\_log\_delivery\_source\_name) | The EventBridge Bus CloudWatch Log Delivery Source Name |
| <a name="output_eventbridge_permission_ids"></a> [eventbridge\_permission\_ids](#output\_eventbridge\_permission\_ids) | The EventBridge Permission IDs |
| <a name="output_eventbridge_permissions"></a> [eventbridge\_permissions](#output\_eventbridge\_permissions) | The EventBridge Permissions created and their attributes |
| <a name="output_eventbridge_pipe_arns"></a> [eventbridge\_pipe\_arns](#output\_eventbridge\_pipe\_arns) | The EventBridge Pipes ARNs |
| <a name="output_eventbridge_pipe_ids"></a> [eventbridge\_pipe\_ids](#output\_eventbridge\_pipe\_ids) | The EventBridge Pipes IDs |
| <a name="output_eventbridge_pipe_role_arns"></a> [eventbridge\_pipe\_role\_arns](#output\_eventbridge\_pipe\_role\_arns) | The ARNs of the IAM role created for EventBridge Pipes |
| <a name="output_eventbridge_pipe_role_names"></a> [eventbridge\_pipe\_role\_names](#output\_eventbridge\_pipe\_role\_names) | The names of the IAM role created for EventBridge Pipes |
| <a name="output_eventbridge_pipes"></a> [eventbridge\_pipes](#output\_eventbridge\_pipes) | The EventBridge Pipes created and their attributes |
| <a name="output_eventbridge_pipes_iam_roles"></a> [eventbridge\_pipes\_iam\_roles](#output\_eventbridge\_pipes\_iam\_roles) | The EventBridge Pipes IAM roles created and their attributes |
| <a name="output_eventbridge_role_arn"></a> [eventbridge\_role\_arn](#output\_eventbridge\_role\_arn) | The ARN of the IAM role created for EventBridge |
| <a name="output_eventbridge_role_name"></a> [eventbridge\_role\_name](#output\_eventbridge\_role\_name) | The name of the IAM role created for EventBridge |
| <a name="output_eventbridge_rule_arns"></a> [eventbridge\_rule\_arns](#output\_eventbridge\_rule\_arns) | The EventBridge Rule ARNs |
| <a name="output_eventbridge_rule_ids"></a> [eventbridge\_rule\_ids](#output\_eventbridge\_rule\_ids) | The EventBridge Rule IDs |
| <a name="output_eventbridge_rules"></a> [eventbridge\_rules](#output\_eventbridge\_rules) | The EventBridge Rules created and their attributes |
| <a name="output_eventbridge_schedule_arns"></a> [eventbridge\_schedule\_arns](#output\_eventbridge\_schedule\_arns) | The EventBridge Schedule ARNs created |
| <a name="output_eventbridge_schedule_group_arns"></a> [eventbridge\_schedule\_group\_arns](#output\_eventbridge\_schedule\_group\_arns) | The EventBridge Schedule Group ARNs |
| <a name="output_eventbridge_schedule_group_ids"></a> [eventbridge\_schedule\_group\_ids](#output\_eventbridge\_schedule\_group\_ids) | The EventBridge Schedule Group IDs |
| <a name="output_eventbridge_schedule_group_states"></a> [eventbridge\_schedule\_group\_states](#output\_eventbridge\_schedule\_group\_states) | The EventBridge Schedule Group states |
| <a name="output_eventbridge_schedule_groups"></a> [eventbridge\_schedule\_groups](#output\_eventbridge\_schedule\_groups) | The EventBridge Schedule Groups created and their attributes |
| <a name="output_eventbridge_schedule_ids"></a> [eventbridge\_schedule\_ids](#output\_eventbridge\_schedule\_ids) | The EventBridge Schedule IDs created |
| <a name="output_eventbridge_schedules"></a> [eventbridge\_schedules](#output\_eventbridge\_schedules) | The EventBridge Schedules created and their attributes |
| <a name="output_eventbridge_targets"></a> [eventbridge\_targets](#output\_eventbridge\_targets) | The EventBridge Targets created and their attributes |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
