# VPCE-Service

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.47.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.47.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lb.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.nlb_tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.alb_ip_targets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_security_group.nlb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.allow_https_from_nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allowed_egress_to_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allowed_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc_endpoint_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service) | resource |
| [aws_vpc_endpoint_service_allowed_principal.allowed_principal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service_allowed_principal) | resource |
| [aws_secretsmanager_secret.pi_account_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.pi_account_id_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_ssm_parameter.allowed_vmc_ips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_logs_bucket"></a> [access\_logs\_bucket](#input\_access\_logs\_bucket) | The S3 bucket to store access logs | `string` | n/a | yes |
| <a name="input_access_logs_prefix"></a> [access\_logs\_prefix](#input\_access\_logs\_prefix) | The S3 prefix for access logs | `string` | n/a | yes |
| <a name="input_alb_arn"></a> [alb\_arn](#input\_alb\_arn) | The ARN of the ALB to target | `string` | n/a | yes |
| <a name="input_alb_listener"></a> [alb\_listener](#input\_alb\_listener) | The ARN of the ALB listener to target | `string` | n/a | yes |
| <a name="input_allowed_principal_secret_name"></a> [allowed\_principal\_secret\_name](#input\_allowed\_principal\_secret\_name) | The name of the Secrets Manager secret containing the AWS account ID allowed to use this VPCE service | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_nation"></a> [nation](#input\_nation) | en for england or ni for northern ireland | `string` | `"en"` | no |
| <a name="input_nlb_name"></a> [nlb\_name](#input\_nlb\_name) | The name of the Network Load Balancer | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix to use for naming resources | `string` | n/a | yes |
| <a name="input_ssm_parameter_name"></a> [ssm\_parameter\_name](#input\_ssm\_parameter\_name) | The name of the SSM parameter to store the allowed IPs | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The Subnet IDs where the Network Load Balancer will be created | `list(string)` | n/a | yes |
| <a name="input_target_alb_sg_id"></a> [target\_alb\_sg\_id](#input\_target\_alb\_sg\_id) | The security group ID of the target ALB to allow inbound from the NLB | `string` | n/a | yes |
| <a name="input_tg_name"></a> [tg\_name](#input\_tg\_name) | The name of the Target Group | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID where the VPC Endpoint Service will be created | `string` | n/a | yes |
| <a name="input_vpces_name"></a> [vpces\_name](#input\_vpces\_name) | The name of the VPC Endpoint Service | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
