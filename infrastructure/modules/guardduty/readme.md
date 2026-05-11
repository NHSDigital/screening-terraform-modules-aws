# GuardDuty

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_findings_label"></a> [findings_label](#module_findings_label) | git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags | feature/BCSS-23189-add-new-modules-to-suppport-bcss |
| <a name="module_this"></a> [this](#module_this) | git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags | feature/BCSS-23189-add-new-modules-to-suppport-bcss |

## Resources

| Name | Type |
|------|------|
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
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional_tag_map](#input_additional_tag_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application_role](#input_application_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`, in the order they appear in the list. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_cloudwatch_event_rule_pattern_detail_type"></a> [cloudwatch_event_rule_pattern_detail_type](#input_cloudwatch_event_rule_pattern_detail_type) | The detail-type pattern used to match GuardDuty events for the CloudWatch rule. | `string` | `"GuardDuty Finding"` | no |
| <a name="input_context"></a> [context](#input_context) | Single object for setting entire context at once. See description of individual variables for details. | `any` | see `context.tf` | no |
| <a name="input_data_classification"></a> [data_classification](#input_data_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data_type](#input_data_type) | The tag data_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input_delimiter) | Delimiter to be used between ID elements. Defaults to `-` (hyphen). | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor_formats](#input_descriptor_formats) | Describe additional descriptors to be output in the `descriptors` output map. | `any` | `{}` | no |
| <a name="input_eks_runtime_monitoring_enabled"></a> [eks_runtime_monitoring_enabled](#input_eks_runtime_monitoring_enabled) | Enable standalone EKS Runtime Monitoring (EKS_RUNTIME_MONITORING). Do not enable alongside runtime_monitoring_enabled. | `bool` | `false` | no |
| <a name="input_enable_cloudwatch"></a> [enable_cloudwatch](#input_enable_cloudwatch) | Create a CloudWatch (EventBridge) rule that forwards GuardDuty findings. The SNS topic itself is created by the separate alerting module. | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_finding_publishing_frequency"></a> [finding_publishing_frequency](#input_finding_publishing_frequency) | Frequency of finding notifications. Valid values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS. Only meaningful for standalone/master accounts. | `string` | `"FIFTEEN_MINUTES"` | no |
| <a name="input_findings_notification_arn"></a> [findings_notification_arn](#input_findings_notification_arn) | ARN of an existing SNS topic that GuardDuty findings should be forwarded to. Leave null to skip target wiring. | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id_length_limit](#input_id_length_limit) | Limit `id` to this many characters (minimum 6). | `number` | `null` | no |
| <a name="input_kubernetes_audit_logs_enabled"></a> [kubernetes_audit_logs_enabled](#input_kubernetes_audit_logs_enabled) | Enable EKS audit log monitoring (EKS_AUDIT_LOGS). | `bool` | `false` | no |
| <a name="input_label_key_case"></a> [label_key_case](#input_label_key_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module. | `string` | `null` | no |
| <a name="input_label_order"></a> [label_order](#input_label_order) | The order in which the labels (ID elements) appear in the `id`. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label_value_case](#input_label_value_case) | Controls the letter case of ID elements (labels) as included in `id`, set as tag values, and output by this module individually. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels_as_tags](#input_labels_as_tags) | Set of labels (ID elements) to include as tags in the `tags` output. | `set(string)` | `["default"]` | no |
| <a name="input_lambda_network_logs_enabled"></a> [lambda_network_logs_enabled](#input_lambda_network_logs_enabled) | Enable Lambda network log monitoring (LAMBDA_NETWORK_LOGS). | `bool` | `false` | no |
| <a name="input_malware_protection_scan_ec2_ebs_volumes_enabled"></a> [malware_protection_scan_ec2_ebs_volumes_enabled](#input_malware_protection_scan_ec2_ebs_volumes_enabled) | Enable EBS Malware Protection scanning of EC2 instance volumes (EBS_MALWARE_PROTECTION). | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on_off_pattern](#input_on_off_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input_project) | ID element. A project identifier, indicating the name or role of the project the resource is for. | `string` | `null` | no |
| <a name="input_public_facing"></a> [public_facing](#input_public_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex_replace_chars](#input_regex_replace_chars) | Terraform regular expression (regex) string. Characters matching the regex will be removed from the ID elements. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input_region) | ID element. Short region abbreviation e.g. 'uw2', 'ew2'. | `string` | `null` | no |
| <a name="input_runtime_monitoring_additional_config"></a> [runtime_monitoring_additional_config](#input_runtime_monitoring_additional_config) | Additional configuration for runtime monitoring agent management. | <pre>object({<br/>    eks_addon_management_enabled         = optional(bool, false)<br/>    ecs_fargate_agent_management_enabled = optional(bool, false)<br/>    ec2_agent_management_enabled         = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_runtime_monitoring_enabled"></a> [runtime_monitoring_enabled](#input_runtime_monitoring_enabled) | Enable Runtime Monitoring for EC2, ECS and EKS resources (RUNTIME_MONITORING). Mutually exclusive with eks_runtime_monitoring_enabled. | `bool` | `false` | no |
| <a name="input_s3_protection_enabled"></a> [s3_protection_enabled](#input_s3_protection_enabled) | Enable S3 Data Events Protection (S3_DATA_EVENTS). | `bool` | `true` | no |
| <a name="input_service"></a> [service](#input_service) | ID element. Service directorate abbreviation, e.g. 'bcss'. | `string` | `null` | no |
| <a name="input_service_category"></a> [service_category](#input_service_category) | The tag service_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks`. | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag_version](#input_tag_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`). | `map(string)` | `{}` | no |
| <a name="input_tool"></a> [tool](#input_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_event_rule_arn"></a> [cloudwatch_event_rule_arn](#output_cloudwatch_event_rule_arn) | ARN of the CloudWatch (EventBridge) rule forwarding GuardDuty findings, if created. |
| <a name="output_detector_arn"></a> [detector_arn](#output_detector_arn) | The ARN of the GuardDuty detector. |
| <a name="output_detector_id"></a> [detector_id](#output_detector_id) | The ID of the GuardDuty detector. |
<!-- END_TF_DOCS -->
<!-- vale on -->
