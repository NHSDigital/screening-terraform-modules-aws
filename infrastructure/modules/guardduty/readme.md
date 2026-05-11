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

No modules.

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
| <a name="input_cloudwatch_event_rule_pattern_detail_type"></a> [cloudwatch_event_rule_pattern_detail_type](#input_cloudwatch_event_rule_pattern_detail_type) | The detail-type pattern used to match GuardDuty events for the CloudWatch rule. | `string` | `"GuardDuty Finding"` | no |
| <a name="input_eks_runtime_monitoring_enabled"></a> [eks_runtime_monitoring_enabled](#input_eks_runtime_monitoring_enabled) | Enable standalone EKS Runtime Monitoring (EKS_RUNTIME_MONITORING). Do not enable alongside runtime_monitoring_enabled. | `bool` | `false` | no |
| <a name="input_enable_cloudwatch"></a> [enable_cloudwatch](#input_enable_cloudwatch) | Create a CloudWatch (EventBridge) rule that forwards GuardDuty findings. The SNS topic itself is created by the separate alerting module. | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input_enabled) | Master switch for the GuardDuty detector. Set to false to disable the detector and all features. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD. | `string` | n/a | yes |
| <a name="input_finding_publishing_frequency"></a> [finding_publishing_frequency](#input_finding_publishing_frequency) | Frequency of finding notifications. Valid values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS. Only meaningful for standalone/master accounts. | `string` | `"FIFTEEN_MINUTES"` | no |
| <a name="input_findings_notification_arn"></a> [findings_notification_arn](#input_findings_notification_arn) | ARN of an existing SNS topic that GuardDuty findings should be forwarded to. Leave null to skip target wiring. | `string` | `null` | no |
| <a name="input_kubernetes_audit_logs_enabled"></a> [kubernetes_audit_logs_enabled](#input_kubernetes_audit_logs_enabled) | Enable EKS audit log monitoring (EKS_AUDIT_LOGS). | `bool` | `false` | no |
| <a name="input_lambda_network_logs_enabled"></a> [lambda_network_logs_enabled](#input_lambda_network_logs_enabled) | Enable Lambda network log monitoring (LAMBDA_NETWORK_LOGS). | `bool` | `false` | no |
| <a name="input_malware_protection_scan_ec2_ebs_volumes_enabled"></a> [malware_protection_scan_ec2_ebs_volumes_enabled](#input_malware_protection_scan_ec2_ebs_volumes_enabled) | Enable EBS Malware Protection scanning of EC2 instance volumes (EBS_MALWARE_PROTECTION). | `bool` | `true` | no |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | Prefix used to name GuardDuty resources (e.g. account/environment identifier). | `string` | n/a | yes |
| <a name="input_runtime_monitoring_additional_config"></a> [runtime_monitoring_additional_config](#input_runtime_monitoring_additional_config) | Additional configuration for runtime monitoring agent management. | <pre>object({<br/>    eks_addon_management_enabled         = optional(bool, false)<br/>    ecs_fargate_agent_management_enabled = optional(bool, false)<br/>    ec2_agent_management_enabled         = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_runtime_monitoring_enabled"></a> [runtime_monitoring_enabled](#input_runtime_monitoring_enabled) | Enable Runtime Monitoring for EC2, ECS and EKS resources (RUNTIME_MONITORING). Mutually exclusive with eks_runtime_monitoring_enabled. | `bool` | `false` | no |
| <a name="input_s3_protection_enabled"></a> [s3_protection_enabled](#input_s3_protection_enabled) | Enable S3 Data Events Protection (S3_DATA_EVENTS). | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input_tags) | Additional tags to apply to all resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_event_rule_arn"></a> [cloudwatch_event_rule_arn](#output_cloudwatch_event_rule_arn) | ARN of the CloudWatch (EventBridge) rule forwarding GuardDuty findings, if created. |
| <a name="output_detector_arn"></a> [detector_arn](#output_detector_arn) | The ARN of the GuardDuty detector. |
| <a name="output_detector_id"></a> [detector_id](#output_detector_id) | The ID of the GuardDuty detector. |
<!-- END_TF_DOCS -->
<!-- vale on -->
