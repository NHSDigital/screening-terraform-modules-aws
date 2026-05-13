# Security Hub

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
| <a name="module_imported_findings_label"></a> [imported_findings_label](#module_imported_findings_label) | `git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags` | feature/BCSS-23189-add-new-modules-to-suppport-bcss |
| <a name="module_this"></a> [this](#module_this) | `git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags` | feature/BCSS-23189-add-new-modules-to-suppport-bcss |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.imported_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.imported_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_securityhub_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_finding_aggregator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_securityhub_standards_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription) | resource |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional_tag_map](#input_additional_tag_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application_role](#input_application_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`, in the order they appear in the list. | `list(string)` | `[]` | no |
| <a name="input_auto_enable_controls"></a> [auto_enable_controls](#input_auto_enable_controls) | Whether new controls added to enabled standards are automatically enabled. | `bool` | `true` | no |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_cloudwatch_event_rule_pattern_detail_type"></a> [cloudwatch_event_rule_pattern_detail_type](#input_cloudwatch_event_rule_pattern_detail_type) | The detail-type pattern used to match Security Hub events for the CloudWatch rule. | `string` | `"Security Hub Findings - Imported"` | no |
| <a name="input_context"></a> [context](#input_context) | Single object for setting entire context at once. See description of individual variables for details. | `any` | see `context.tf` | no |
| <a name="input_control_finding_generator"></a> [control_finding_generator](#input_control_finding_generator) | How Security Hub generates findings for security checks. Valid values: SECURITY_CONTROL (consolidated, recommended) or STANDARD_CONTROL (one finding per standard). | `string` | `"SECURITY_CONTROL"` | no |
| <a name="input_data_classification"></a> [data_classification](#input_data_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data_type](#input_data_type) | The tag data_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input_delimiter) | Delimiter to be used between ID elements. Defaults to `-` (hyphen). | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor_formats](#input_descriptor_formats) | Describe additional descriptors to be output in the `descriptors` output map. | `any` | `{}` | no |
| <a name="input_enable_cloudwatch"></a> [enable_cloudwatch](#input_enable_cloudwatch) | Create a CloudWatch (EventBridge) rule that forwards Security Hub imported findings. The SNS topic itself is created by the separate alerting module. | `bool` | `true` | no |
| <a name="input_enable_default_standards"></a> [enable_default_standards](#input_enable_default_standards) | Whether to enable the AWS-recommended default standards (AWS Foundational Security Best Practices and CIS AWS Foundations Benchmark) when Security Hub is first enabled in this account/region. | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_enabled_standards"></a> [enabled_standards](#input_enabled_standards) | A list of Security Hub standards/rulesets to subscribe to. Values can be a short identifier or a full ARN. | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_finding_aggregator_enabled"></a> [finding_aggregator_enabled](#input_finding_aggregator_enabled) | Whether to create a Security Hub finding aggregator to consolidate findings across regions. | `bool` | `false` | no |
| <a name="input_finding_aggregator_linking_mode"></a> [finding_aggregator_linking_mode](#input_finding_aggregator_linking_mode) | Linking mode for the finding aggregator. One of: ALL_REGIONS, ALL_REGIONS_EXCEPT_SPECIFIED, SPECIFIED_REGIONS. | `string` | `"ALL_REGIONS"` | no |
| <a name="input_finding_aggregator_regions"></a> [finding_aggregator_regions](#input_finding_aggregator_regions) | List of regions used by the finding aggregator. Required when `finding_aggregator_linking_mode` is `SPECIFIED_REGIONS` or `ALL_REGIONS_EXCEPT_SPECIFIED`. | `list(string)` | `[]` | no |
| <a name="input_findings_notification_arn"></a> [findings_notification_arn](#input_findings_notification_arn) | ARN of an existing SNS topic that Security Hub imported findings should be forwarded to. Leave null to skip target wiring. | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id_length_limit](#input_id_length_limit) | Limit `id` to this many characters (minimum 6). | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label_key_case](#input_label_key_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module. | `string` | `null` | no |
| <a name="input_label_order"></a> [label_order](#input_label_order) | The order in which the labels (ID elements) appear in the `id`. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label_value_case](#input_label_value_case) | Controls the letter case of ID elements (labels) as included in `id`, set as tag values, and output by this module individually. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels_as_tags](#input_labels_as_tags) | Set of labels (ID elements) to include as tags in the `tags` output. | `set(string)` | `["default"]` | no |
| <a name="input_name"></a> [name](#input_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on_off_pattern](#input_on_off_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input_project) | ID element. A project identifier, indicating the name or role of the project the resource is for. | `string` | `null` | no |
| <a name="input_public_facing"></a> [public_facing](#input_public_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex_replace_chars](#input_regex_replace_chars) | Terraform regular expression (regex) string. Characters matching the regex will be removed from the ID elements. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input_region) | ID element. Short region abbreviation e.g. 'uw2', 'ew2'. | `string` | `null` | no |
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
| <a name="output_account_arn"></a> [account_arn](#output_account_arn) | The ARN of the Security Hub hub resource for this account. |
| <a name="output_account_id"></a> [account_id](#output_account_id) | The AWS account ID that Security Hub has been enabled in. |
| <a name="output_cloudwatch_event_rule_arn"></a> [cloudwatch_event_rule_arn](#output_cloudwatch_event_rule_arn) | ARN of the CloudWatch (EventBridge) rule forwarding Security Hub imported findings, if created. |
| <a name="output_enabled_standards_subscriptions"></a> [enabled_standards_subscriptions](#output_enabled_standards_subscriptions) | Map of subscribed Security Hub standards keyed by the input identifier, with the resulting subscription ARN as the value. |
| <a name="output_finding_aggregator_arn"></a> [finding_aggregator_arn](#output_finding_aggregator_arn) | ARN of the Security Hub finding aggregator, if created. |
<!-- END_TF_DOCS -->
<!-- vale on -->
