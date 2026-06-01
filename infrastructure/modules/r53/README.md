# r53

Creates Route53 hosted zones, Route53 Resolver endpoints, and Route53
Resolver DNS Firewall rule groups for screening shared-resource stacks.
This is a thin screening wrapper around the community
[`terraform-aws-modules/route53/aws`](https://registry.terraform.io/modules/terraform-aws-modules/route53/aws/latest)
module set, with naming and tagging supplied by the central `tags` module via
`context.tf`.

## Usage

### Private hosted zone with records and cross-account authorization

```hcl
module "r53" {
  source  = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/r53?ref=<tag>"
  context = module.label.context

  hosted_zones = {
    internal = {
      name         = "screening.internal"
      private_zone = true
      ignore_vpc   = true

      vpc = {
        primary = {
          vpc_id     = module.vpc.vpc_id
          vpc_region = "eu-west-2"
        }
      }

      vpc_association_authorizations = {
        shared-services = {
          vpc_id     = "vpc-0123456789abcdef0"
          vpc_region = "eu-west-2"
        }
      }

      records = {
        api = {
          type = "A"
          alias = {
            name    = module.alb.dns_name
            zone_id = module.alb.zone_id
          }
        }
      }
    }
  }
}
```

### Inbound and outbound resolver endpoints

```hcl
module "r53" {
  source  = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/r53?ref=<tag>"
  context = module.label.context

  resolver_endpoints = {
    inbound = {
      direction = "INBOUND"
      type      = "IPV4"
      protocols = ["Do53"]
      vpc_id    = module.vpc.vpc_id

      ip_address = [
        { subnet_id = module.vpc.private_subnets[0] },
        { subnet_id = module.vpc.private_subnets[1] },
      ]

      security_group_ingress_rules = {
        subnet-a = {
          cidr_ipv4   = module.vpc.private_subnets_cidr_blocks[0]
          description = "Allow inbound DNS queries from subnet A"
        }
        subnet-b = {
          cidr_ipv4   = module.vpc.private_subnets_cidr_blocks[1]
          description = "Allow inbound DNS queries from subnet B"
        }
      }

      security_group_egress_rules = {
        subnet-a = {
          cidr_ipv4   = module.vpc.private_subnets_cidr_blocks[0]
          description = "Allow DNS responses to subnet A"
        }
        subnet-b = {
          cidr_ipv4   = module.vpc.private_subnets_cidr_blocks[1]
          description = "Allow DNS responses to subnet B"
        }
      }
    }

    outbound = {
      direction = "OUTBOUND"
      type      = "IPV4"
      protocols = ["Do53", "DoH"]
      vpc_id    = module.vpc.vpc_id

      ip_address = [
        { subnet_id = module.vpc.private_subnets[0] },
        { subnet_id = module.vpc.private_subnets[1] },
      ]

      rules = {
        onprem = {
          domain_name = "corp.internal."
          rule_type   = "FORWARD"
          vpc_id      = module.vpc.vpc_id
          target_ip = [
            { ip = "10.20.0.10" },
            { ip = "10.20.0.11" },
          ]
        }
      }
    }
  }
}
```

### Resolver DNS Firewall rule group

```hcl
module "r53" {
  source  = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/r53?ref=<tag>"
  context = module.label.context

  resolver_firewall_rule_groups = {
    default = {
      rules = {
        block-malware = {
          priority       = 100
          action         = "BLOCK"
          block_response = "NODATA"
          domains        = ["bad.example.", "malware.example."]
        }
        allow-aws = {
          priority = 110
          action   = "ALLOW"
          domains  = ["amazonaws.com.", "amazon.com."]
        }
      }
    }
  }
}
```

## Conventions

- Hosted zone names are caller-supplied DNS names; the wrapper does not derive
  them from `context.tf`.
- Resolver endpoint and firewall rule group names default to context-derived,
  deterministic names based on the item key.
- All resources inherit the standard screening tag set, and per-item `tags`
  are merged on top.
- Resolver endpoint resources default to `var.aws_region` when no per-item
  `region` is supplied.

## What this module does NOT do

- Create `aws_route53_zone_association` resources for VPCs in other accounts.
  As with the upstream module, only
  `aws_route53_vpc_association_authorization` is handled here.
- Create `aws_route53_resolver_firewall_rule_group_association` resources.
  Associate firewall rule groups to VPCs in the consumer stack once the shared
  resource exists.
- Abstract every Route53 feature into separate screening opinions. This module
  stays deliberately thin and forwards most behavior to the upstream module.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
