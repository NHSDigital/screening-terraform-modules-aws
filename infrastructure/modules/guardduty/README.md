# GuardDuty

NHS Screening wrapper for AWS GuardDuty that enforces the platform's baseline controls and consumes the shared `context.tf` for naming and tagging.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| Threat detection | GuardDuty detector enabled when `enable_detector = true` |
| S3 protection | S3 Data Events monitoring enabled by default (`s3_protection_enabled = true`) |
| EBS malware scanning | EBS Malware Protection enabled by default (`malware_protection_scan_ec2_ebs_volumes_enabled = true`) |
| Finding notifications | CloudWatch Event rule forwards findings to SNS by default (`enable_cloudwatch = true`) |
| Resource enable/disable | Creation gated by `module.this.enabled` |
| Tagging and naming | Uses shared `context.tf` (`module.this`) for tags and naming |

## Usage

### Minimal detector with default protections

```hcl
module "guardduty" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/guardduty?ref=main"

  service     = "bcss"
  project     = "security"
  environment = "prod"
  name        = "detector"

  enable_detector = true
}
```

### Production detector with all protections and SNS forwarding

```hcl
module "guardduty" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/guardduty?ref=main"

  service     = "bcss"
  project     = "security"
  environment = "prod"
  name        = "detector"

  enable_detector = true

  # Protection features
  s3_protection_enabled                           = true
  malware_protection_scan_ec2_ebs_volumes_enabled = true
  kubernetes_audit_logs_enabled                   = true
  lambda_network_logs_enabled                     = true
  runtime_monitoring_enabled                      = true

  runtime_monitoring_additional_config = {
    eks_addon_management_enabled         = true
    ecs_fargate_agent_management_enabled = true
    ec2_agent_management_enabled         = true
  }

  # Forward findings to SNS
  enable_cloudwatch          = true
  findings_notification_arn  = module.sns_alerts.topic_arn
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}
```

### Detector with minimal protections (non-production use)

```hcl
module "guardduty_dev" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/guardduty?ref=main"

  service     = "bcss"
  project     = "security"
  environment = "dev"
  name        = "detector"

  enable_detector = true

  # Minimal protections for cost control in dev
  s3_protection_enabled                           = false
  malware_protection_scan_ec2_ebs_volumes_enabled = false
  kubernetes_audit_logs_enabled                   = false
  lambda_network_logs_enabled                     = false
  runtime_monitoring_enabled                      = false

  # Disable SNS forwarding in dev
  enable_cloudwatch = false
}
```

## Conventions

- `enable_detector` defaults to `false`; you must explicitly enable it.
- S3 protection (`s3_protection_enabled`) and EBS malware scanning (`malware_protection_scan_ec2_ebs_volumes_enabled`) default to `true`.
- Runtime monitoring features (EKS, ECS, Lambda) default to `false`; enable based on workload requirements.
- `runtime_monitoring_enabled` and `eks_runtime_monitoring_enabled` are mutually exclusive; `RUNTIME_MONITORING` already covers EKS.
- CloudWatch Event rule (`enable_cloudwatch`) defaults to `true` and creates a forwarding rule; provide `findings_notification_arn` to wire it to an SNS topic.
- `finding_publishing_frequency` defaults to `FIFTEEN_MINUTES` for faster detection; adjust to `ONE_HOUR` or `SIX_HOURS` if lower alert volume is acceptable.
- The EventBridge rule uses a separate context label (`findings`) so its name/tags are distinct from the detector.

## What this module does NOT do

- Create or manage SNS topics for findings; you must create the topic separately and pass its ARN via `findings_notification_arn`.
- Configure GuardDuty member accounts or delegated administrator relationships; this module manages standalone or master account detectors only.
- Export findings to S3 or other destinations; use AWS GuardDuty's native export configuration outside this module if required.
- Automatically enable runtime monitoring agents on EC2/ECS/EKS; the module enables the GuardDuty feature, but agent deployment is separate.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.14.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_findings_label"></a> [findings\_label](#module\_findings\_label) | ../tags | n/a |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_event_rule.findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_guardduty_detector.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_detector_feature.ebs_malware_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.eks_audit_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.eks_runtime_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.lambda_network_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.runtime_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.s3_data_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_cloudwatch_event_rule_pattern_detail_type"></a> [cloudwatch\_event\_rule\_pattern\_detail\_type](#input\_cloudwatch\_event\_rule\_pattern\_detail\_type) | The detail-type pattern used to match GuardDuty events for the CloudWatch rule. | `string` | `"GuardDuty Finding"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_eks_runtime_monitoring_enabled"></a> [eks\_runtime\_monitoring\_enabled](#input\_eks\_runtime\_monitoring\_enabled) | Enable standalone EKS Runtime Monitoring (EKS\_RUNTIME\_MONITORING). Do not enable alongside runtime\_monitoring\_enabled. | `bool` | `false` | no |
| <a name="input_enable_cloudwatch"></a> [enable\_cloudwatch](#input\_enable\_cloudwatch) | Create a CloudWatch (EventBridge) rule that forwards GuardDuty findings. The SNS topic itself is created by the separate alerting module. | `bool` | `true` | no |
| <a name="input_enable_detector"></a> [enable\_detector](#input\_enable\_detector) | Enable the GuardDuty detector. | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_finding_publishing_frequency"></a> [finding\_publishing\_frequency](#input\_finding\_publishing\_frequency) | Frequency of finding notifications. Valid values: FIFTEEN\_MINUTES, ONE\_HOUR, SIX\_HOURS. Only meaningful for standalone/master accounts. | `string` | `"FIFTEEN_MINUTES"` | no |
| <a name="input_findings_notification_arn"></a> [findings\_notification\_arn](#input\_findings\_notification\_arn) | ARN of an existing SNS topic that GuardDuty findings should be forwarded to. Leave null to skip target wiring. | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_kubernetes_audit_logs_enabled"></a> [kubernetes\_audit\_logs\_enabled](#input\_kubernetes\_audit\_logs\_enabled) | Enable EKS audit log monitoring (EKS\_AUDIT\_LOGS). | `bool` | `false` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_lambda_network_logs_enabled"></a> [lambda\_network\_logs\_enabled](#input\_lambda\_network\_logs\_enabled) | Enable Lambda network log monitoring (LAMBDA\_NETWORK\_LOGS). | `bool` | `false` | no |
| <a name="input_malware_protection_scan_ec2_ebs_volumes_enabled"></a> [malware\_protection\_scan\_ec2\_ebs\_volumes\_enabled](#input\_malware\_protection\_scan\_ec2\_ebs\_volumes\_enabled) | Enable EBS Malware Protection scanning of EC2 instance volumes (EBS\_MALWARE\_PROTECTION). | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_runtime_monitoring_additional_config"></a> [runtime\_monitoring\_additional\_config](#input\_runtime\_monitoring\_additional\_config) | Additional configuration for runtime monitoring agent management. | <pre>object({<br/>    eks_addon_management_enabled         = optional(bool, false)<br/>    ecs_fargate_agent_management_enabled = optional(bool, false)<br/>    ec2_agent_management_enabled         = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_runtime_monitoring_enabled"></a> [runtime\_monitoring\_enabled](#input\_runtime\_monitoring\_enabled) | Enable Runtime Monitoring for EC2, ECS and EKS resources (RUNTIME\_MONITORING). Mutually exclusive with eks\_runtime\_monitoring\_enabled. | `bool` | `false` | no |
| <a name="input_s3_protection_enabled"></a> [s3\_protection\_enabled](#input\_s3\_protection\_enabled) | Enable S3 Data Events Protection (S3\_DATA\_EVENTS). | `bool` | `true` | no |
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
| <a name="output_cloudwatch_event_rule_arn"></a> [cloudwatch\_event\_rule\_arn](#output\_cloudwatch\_event\_rule\_arn) | ARN of the CloudWatch (EventBridge) rule forwarding GuardDuty findings, if created. |
| <a name="output_detector_arn"></a> [detector\_arn](#output\_detector\_arn) | The ARN of the GuardDuty detector. |
| <a name="output_detector_id"></a> [detector\_id](#output\_detector\_id) | The ID of the GuardDuty detector. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
