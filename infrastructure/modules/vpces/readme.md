# VPCE-Service

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
| [aws_secretsmanager_secret.pi-account-id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.pi-account-id-version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_ssm_parameter.allowed_vmc_ips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_subnet.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs_bucket"></a> [access_logs_bucket](#input_access_logs_bucket) | The S3 bucket to store access logs | `string` | n/a | yes |
| <a name="input_access_logs_prefix"></a> [access_logs_prefix](#input_access_logs_prefix) | The S3 prefix for access logs | `string` | n/a | yes |
| <a name="input_alb_arn"></a> [alb_arn](#input_alb_arn) | The ARN of the ALB to target | `string` | n/a | yes |
| <a name="input_alb_listener"></a> [alb_listener](#input_alb_listener) | The ARN of the ALB listener to target | `string` | n/a | yes |
| <a name="input_allowed_principal_secret_name"></a> [allowed_principal_secret_name](#input_allowed_principal_secret_name) | The name of the Secrets Manager secret containing the AWS account ID allowed to use this VPCE service | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_nation"></a> [nation](#input_nation) | en for england or ni for northern ireland | `string` | `"en"` | no |
| <a name="input_nlb_name"></a> [nlb_name](#input_nlb_name) | The name of the Network Load Balancer | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input_prefix) | The prefix to use for naming resources | `string` | n/a | yes |
| <a name="input_ssm_parameter_name"></a> [ssm_parameter_name](#input_ssm_parameter_name) | The name of the SSM parameter to store the allowed IPs | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids) | The Subnet IDs where the Network Load Balancer will be created | `list(string)` | n/a | yes |
| <a name="input_target_alb_sg_id"></a> [target_alb_sg_id](#input_target_alb_sg_id) | The security group ID of the target ALB to allow inbound from the NLB | `string` | n/a | yes |
| <a name="input_tg_name"></a> [tg_name](#input_tg_name) | The name of the Target Group | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | The VPC ID where the VPC Endpoint Service will be created | `string` | n/a | yes |
| <a name="input_vpces_name"></a> [vpces_name](#input_vpces_name) | The name of the VPC Endpoint Service | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- vale on -->
