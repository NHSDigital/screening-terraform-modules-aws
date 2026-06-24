# AWS Application / Network Load Balancer Terraform module

Thin NHS wrapper around [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws) that enforces the screening platform's baseline controls.

## What this module enforces

| Setting | Value | Reason |
|---|---|---|
| `drop_invalid_header_fields` | `true` (ALB only) | Prevents HTTP header injection attacks |

## Usage

### Internet-facing ALB with HTTPS

```hcl
module "alb" {
  source = "../../modules/alb"

  context     = module.this.context
  stack       = "web"
  name        = "bcss-web"
  label_order = ["service", "environment", "stack", "name"]

  vpc_id  = data.aws_vpc.selected.id
  subnets = data.aws_subnets.public.ids

  access_logs = {
    bucket  = module.logs_bucket.id
    prefix  = terraform.workspace
    enabled = true
  }

  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP from internet — redirected to HTTPS by listener"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS from internet"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    https_out = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS to targets"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  # HTTP → HTTPS redirect on port 80 is added automatically by this module.
  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn = local.acm_certificate_arn
      forward = {
        target_group_key = "web"
      }
    }
  }

  target_groups = {
    web = {
      port        = 443
      protocol    = "HTTPS"
      target_type = "ip"
      health_check = {
        protocol            = "HTTPS"
        path                = "/health"
        matcher             = "200"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        interval            = 60
      }
    }
  }
}
```

### ALB with WAF association

```hcl
module "alb" {
  source = "../../modules/alb"

  context = module.this.context
  name    = "bcss-web"

  vpc_id  = data.aws_vpc.selected.id
  subnets = data.aws_subnets.public.ids

  listeners     = { ... }
  target_groups = { ... }

  web_acl_arn = module.waf.web_acl_arn
}
```

### Internal NLB

```hcl
module "nlb" {
  source = "../../modules/alb"

  context = module.this.context
  name    = "internal-nlb"

  load_balancer_type = "network"
  internal           = true
  vpc_id             = data.aws_vpc.selected.id
  subnets            = data.aws_subnets.private.ids

  security_group_ingress_rules = {
    tcp = {
      from_port   = 8080
      to_port     = 8080
      ip_protocol = "tcp"
      description = "Internal TCP traffic"
      cidr_ipv4   = data.aws_vpc.selected.cidr_block
    }
  }

  security_group_egress_rules = {
    tcp_out = {
      from_port   = 8080
      to_port     = 8080
      ip_protocol = "tcp"
      cidr_ipv4   = data.aws_vpc.selected.cidr_block
    }
  }

  listeners = {
    tcp = {
      port     = 8080
      protocol = "TCP"
      forward  = { target_group_key = "service" }
    }
  }

  target_groups = {
    service = {
      port        = 8080
      protocol    = "TCP"
      target_type = "ip"
      health_check = {
        protocol = "TCP"
        port     = "8080"
      }
    }
  }
}
```

## Conventions

* The load balancer name is derived from `module.this.id` and cannot be overridden — pass `context`, `name`, and `label_order` to control the generated name.
* `internal` defaults to `false` (internet-facing). Set `internal = true` for ALBs and NLBs that should only be reachable from within the VPC.
* `enable_deletion_protection` defaults to `true`. Set it to `false` for non-production environments where the load balancer needs to be freely destroyed.
* HTTP-to-HTTPS redirect on port 80 is added automatically for ALBs (`enable_http_https_redirect = true` by default). Set to `false` if you need custom HTTP listener behaviour or the ALB is not serving HTTPS traffic. Does not apply to NLBs.
* Security group rules are caller-supplied via `security_group_ingress_rules` and `security_group_egress_rules`. This supports both ALB (HTTP/HTTPS) and NLB (TCP/TLS) patterns without constraining port numbers.
* Access logging is optional. Supply an S3 bucket ARN via `access_logs` to enable it. NHS production environments should always enable access logging.
* For NLBs, `drop_invalid_header_fields` is set to `null` automatically — this argument is only valid for ALBs.

## What this module does NOT do

* Create SSL/TLS certificates — use the `acm` module and pass the certificate ARN into `listeners`.
* Create an S3 bucket for access logs — use the `s3-bucket` module and pass the bucket ID via `access_logs.bucket`.
* Create Route53 DNS records — create an alias record pointing to `module.alb.dns_name` and `module.alb.zone_id` in your stack.
* Create a WAF Web ACL — use the `waf` module and pass the ARN via `web_acl_arn`.
* Enforce a minimum TLS policy — callers must specify `ssl_policy` on HTTPS listeners; use `ELBSecurityPolicy-TLS13-1-2-Res-2021-06` or later.

## Outputs

| Name | Description | Used by |
|---|---|---|
| `arn` | ARN of the load balancer | WAF ACL association |
| `dns_name` | DNS name of the load balancer | Route53 alias records |
| `zone_id` | Hosted zone ID of the load balancer | Route53 alias records |
| `listeners` | Map of listeners and their attributes | ECS task `depends_on` |
| `target_groups` | Map of target groups and their attributes | ECS task `target_group_arn` |
| `security_group_id` | ID of the load balancer security group | ECS task security group rules |

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5.7 |
| aws | >= 6.28 |

<!-- END_TF_DOCS -->
<!-- markdownlint-enable -->
<!-- vale on -->
