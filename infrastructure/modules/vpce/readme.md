# VPC Endpoints

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
| [aws_route53_record.vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.vpce](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.vpce_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpce_ingress_from_cidr_range](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpce_ingress_from_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc_endpoint.endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hosted_zone_id"></a> [hosted_zone_id](#input_hosted_zone_id) | Set the hosted zone id if you would like a R53 alias record set up for this VPCE | `any` | n/a | yes |
| <a name="input_hosted_zone_name"></a> [hosted_zone_name](#input_hosted_zone_name) | Set the hosted zone name if you would like a R53 alias record set up for this VPCE | `any` | n/a | yes |
| <a name="input_inbound_port"></a> [inbound_port](#input_inbound_port) | TCP port for which ingress will be allowed to VPCE | `any` | n/a | yes |
| <a name="input_ingress_cidr_range"></a> [ingress_cidr_range](#input_ingress_cidr_range) | Optional CIDR range that will be allowed to send traffic to VPCE e.g. the VPC cidr range | `string` | `""` | no |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | the environment and project | `any` | n/a | yes |
| <a name="input_outbound_port"></a> [outbound_port](#input_outbound_port) | TCP port for which egress will be allowed to VPCE | `any` | n/a | yes |
| <a name="input_service_name"></a> [service_name](#input_service_name) | VPC endpoint service name to connect to | `any` | n/a | yes |
| <a name="input_source_sg_id"></a> [source_sg_id](#input_source_sg_id) | Optional id of source SG that will be allowed to send traffic to VPCE e.g. RDS SG | `string` | `""` | no |
| <a name="input_subnet_azs"></a> [subnet_azs](#input_subnet_azs) | AZs of subnets to associate - this must match the subnets of the remote VPC endpoint service e.g. euw2-az2, euw2-az3 | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids) | Subnet ids | `any` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | VPC id | `any` | n/a | yes |
| <a name="input_vpce_name"></a> [vpce_name](#input_vpce_name) | The name of the VPCE | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpce_arn"></a> [vpce_arn](#output_vpce_arn) | n/a |
| <a name="output_vpce_dns_name"></a> [vpce_dns_name](#output_vpce_dns_name) | n/a |
| <a name="output_vpce_hosted_zone_id"></a> [vpce_hosted_zone_id](#output_vpce_hosted_zone_id) | n/a |
<!-- END_TF_DOCS -->
<!-- vale on -->
