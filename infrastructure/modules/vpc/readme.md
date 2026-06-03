# VPC

Screening wrapper around the [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) upstream module (v6.6.1), providing a standardised four-tier subnet layout.

## subnet tiers

| Tier | Prefix | Purpose |
|------|--------|---------|
| Firewall | /28 | Network Firewall endpoints |
| Public | /24 | Public-facing resources, NAT gateways |
| Private | /23 | Private workloads with internet access via NAT |
| Isolated | /23 | Fully isolated, no internet route |

subnet CIDRs are auto-calculated from the VPC CIDR (assumes a /16) across all available AZs in the region. Explicit overrides are available via `firewall_subnets`, `public_subnets`, `private_subnets`, and `isolated_subnets` variables.

## Features

- **Naming and tagging** via `context.tf` / `module.this` (tags module v2.5.0)
- **NAT gateways** — one per AZ by default, with `single_nat_gateway` option for cost savings
- **VPC Flow Logs** — enabled by default, sending to CloudWatch Logs with a 365-day retention. Implemented as standalone resources (upstream deprecated flow logs in v6.x, removing in v7.0.0)
- **Security defaults** — default security group adopted and stripped of all rules
- **Firewall subnets** — standalone resources (upstream module has no firewall tier)

## Usage

```terraform
module "vpc" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc?ref=<version>"

  environment = "dev"
  service     = "bcss"
  name        = "vpc"

  vpc_cidr           = "10.0.0.0/16"
  single_nat_gateway = true  # cost saving for non-prod

  flow_log_kms_key_id = aws_kms_key.cloudwatch.arn  # optional encryption
}
```

## Key variables

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_cidr` | VPC CIDR block (/16 for auto-calculation) | `10.0.0.0/16` |
| `single_nat_gateway` | Use one shared NAT instead of per-AZ | `false` |
| `enable_flow_log` | Enable VPC flow logs | `true` |
| `flow_log_retention_in_days` | CloudWatch log retention | `365` |
| `flow_log_traffic_type` | ACCEPT, REJECT, or ALL | `ALL` |
| `flow_log_kms_key_id` | KMS key arn for log encryption | `null` |
| `map_public_ip_on_launch` | Auto-assign public IPs in public subnets | `false` |

## Key outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | The VPC ID |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private (NAT-routed) subnet IDs |
| `isolated_subnet_ids` | Isolated (no internet) subnet IDs |
| `firewall_subnet_ids` | Firewall subnet IDs |
| `nat_public_ips` | NAT gateway Elastic IPs |
| `flow_log_id` | VPC Flow Log ID |
