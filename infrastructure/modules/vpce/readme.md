# VPC Endpoints

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_route53_record.vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.vpce](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.vpce_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpce_ingress_from_cidr_range](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpce_ingress_from_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc_endpoint.endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | Set the hosted zone id if you would like a R53 alias record set up for this VPCE | `string` | n/a | yes |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | Set the hosted zone name if you would like a R53 alias record set up for this VPCE | `string` | n/a | yes |
| <a name="input_inbound_port"></a> [inbound\_port](#input\_inbound\_port) | TCP port for which ingress will be allowed to VPCE | `number` | n/a | yes |
| <a name="input_ingress_cidr_range"></a> [ingress\_cidr\_range](#input\_ingress\_cidr\_range) | Optional CIDR range that will be allowed to send traffic to VPCE e.g. the VPC cidr range | `string` | `""` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | the environment and project | `string` | n/a | yes |
| <a name="input_outbound_port"></a> [outbound\_port](#input\_outbound\_port) | TCP port for which egress will be allowed to VPCE | `number` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | VPC endpoint service name to connect to | `string` | n/a | yes |
| <a name="input_source_sg_id"></a> [source\_sg\_id](#input\_source\_sg\_id) | Optional id of source SG that will be allowed to send traffic to VPCE e.g. RDS SG | `string` | `""` | no |
| <a name="input_subnet_azs"></a> [subnet\_azs](#input\_subnet\_azs) | AZs of subnets to associate - this must match the subnets of the remote VPC endpoint service e.g. euw2-az2, euw2-az3 | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet ids | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC id | `string` | n/a | yes |
| <a name="input_vpce_name"></a> [vpce\_name](#input\_vpce\_name) | The name of the VPCE | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_vpce_arn"></a> [vpce\_arn](#output\_vpce\_arn) | ARN of the VPC interface endpoint |
| <a name="output_vpce_dns_name"></a> [vpce\_dns\_name](#output\_vpce\_dns\_name) | DNS name of the VPC interface endpoint |
| <a name="output_vpce_hosted_zone_id"></a> [vpce\_hosted\_zone\_id](#output\_vpce\_hosted\_zone\_id) | Hosted zone ID for the VPC interface endpoint DNS |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
