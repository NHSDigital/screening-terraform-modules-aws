# Inspector

Thin wrapper around [`cloudposse/inspector/aws`](https://registry.terraform.io/modules/cloudposse/inspector/aws/latest)
(pinned to `0.4.0`) so screening services can enable AWS Inspector
Classic with consistent naming and tagging via the shared
`context.tf`.

For Inspector v2 (continuous scanning of EC2, ECR and Lambda),
build a separate module using the `aws_inspector2_*` resources.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| Periodic assessments | CloudWatch Event rule triggers Inspector on a schedule (`schedule_expression`) |
| Rule package validation | Only valid short identifiers (`cve`, `cis`, `nr`, `sbp`) are accepted |
| Tagging and naming | Uses shared `context.tf` (`module.this`) for tags and naming |
| Resource enable/disable | Creation gated by `module.this.enabled` |

## Usage

### Minimal Inspector Classic with CVE and CIS rules

```hcl
module "inspector" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/inspector?ref=<tag>"

  service     = "bcss"
  project     = "security"
  environment = "prod"
  name        = "classic"

  enabled_rules = ["cve", "cis"]
}
```

### Production Inspector with all rule packages and SNS notifications

```hcl
module "inspector" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/inspector?ref=<tag>"

  service     = "bcss"
  project     = "security"
  environment = "prod"
  name        = "full-scan"

  enabled_rules = ["cve", "cis", "nr", "sbp"]

  # Run assessments daily
  schedule_expression = "rate(1 day)"
  assessment_duration = "7200"

  # Send notifications to SNS
  assessment_event_subscription = {
    completed = {
      event     = "ASSESSMENT_RUN_COMPLETED"
      topic_arn = module.sns_alerts.topic_arn
    }
    failed = {
      event     = "ASSESSMENT_RUN_STATE_CHANGED"
      topic_arn = module.sns_alerts.topic_arn
    }
  }
}
```

### Custom IAM role for Inspector execution

```hcl
resource "aws_iam_role" "inspector" {
  name = "custom-inspector-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "inspector" {
  role       = aws_iam_role.inspector.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonInspectorServiceRolePolicy"
}

module "inspector" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/inspector?ref=<tag>"

  service     = "bcss"
  project     = "security"
  environment = "prod"
  name        = "custom-role"

  enabled_rules = ["cve", "cis"]

  create_iam_role = false
  iam_role_arn    = aws_iam_role.inspector.arn
}
```

## Conventions

- `enabled_rules` is required and must contain at least one valid rule package identifier.
- Valid short identifiers: `cve` (Common Vulnerabilities & Exposures), `cis` (CIS benchmarks), `nr` (Network Reachability), `sbp` (Security Best Practices).
- `schedule_expression` defaults to `rate(7 days)`; adjust based on compliance requirements.
- `assessment_duration` defaults to `3600` seconds (1 hour); increase for larger environments.
- `create_iam_role` defaults to `false`; the upstream module creates a role if set to `true`, or you can provide an existing role via `iam_role_arn`.
- `assessment_event_subscription` is a map for stability; use descriptive keys like `completed`, `failed`, `started`.

## What this module does NOT do

- Support Inspector v2 (use native `aws_inspector2_*` resources for that).
- Create SNS topics for notifications; you must create the topic separately and pass its ARN.
- Install or configure the Inspector agent on EC2 instances; that is managed separately via Systems Manager or user data scripts.
- Support cross-account or organisation-wide Inspector delegation; this module manages standalone account deployments only.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.27 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_inspector"></a> [inspector](#module\_inspector) | cloudposse/inspector/aws | 0.4.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_assessment_duration"></a> [assessment\_duration](#input\_assessment\_duration) | Maximum duration of the Inspector assessment run, in seconds. | `string` | `"3600"` | no |
| <a name="input_assessment_event_subscription"></a> [assessment\_event\_subscription](#input\_assessment\_event\_subscription) | Map of assessment template event subscriptions. Each entry sends<br/>notifications about a specified assessment template event to a designated<br/>SNS topic. Keys are caller-supplied identifiers used as the map key for<br/>`for_each`-style stability. | <pre>map(object({<br/>    event     = string<br/>    topic_arn = string<br/>  }))</pre> | `{}` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Whether to create the IAM role used by the CloudWatch event rule to start the Inspector assessment. Set to false to supply an existing role via `iam_role_arn`. | `bool` | `false` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_enabled_rules"></a> [enabled\_rules](#input\_enabled\_rules) | A list of AWS Inspector Classic rule packages to run on a periodic basis.<br/>Valid short identifiers (resolved per-region by the upstream module):<br/>  cve - Common Vulnerabilities & Exposures<br/>  cis - Center for Internet Security benchmarks<br/>  nr  - Network Reachability<br/>  sbp - Security Best Practices | `list(string)` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_event_rule_description"></a> [event\_rule\_description](#input\_event\_rule\_description) | Description of the CloudWatch event rule that triggers the Inspector assessment. | `string` | `"Trigger an AWS Inspector Assessment"` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | ARN of an existing IAM role used to start the Inspector assessment. Only used when `create_iam_role` is false. | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | AWS CloudWatch schedule expression controlling how often assessments run. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html | `string` | `"rate(7 days)"` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_aws_cloudwatch_event_rule"></a> [aws\_cloudwatch\_event\_rule](#output\_aws\_cloudwatch\_event\_rule) | The CloudWatch event rule that triggers the Inspector assessment. |
| <a name="output_aws_cloudwatch_event_target"></a> [aws\_cloudwatch\_event\_target](#output\_aws\_cloudwatch\_event\_target) | The CloudWatch event target wiring the schedule to the Inspector assessment. |
| <a name="output_aws_inspector_assessment_template"></a> [aws\_inspector\_assessment\_template](#output\_aws\_inspector\_assessment\_template) | The AWS Inspector assessment template. |
| <a name="output_inspector_assessment_target"></a> [inspector\_assessment\_target](#output\_inspector\_assessment\_target) | The AWS Inspector assessment target. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
