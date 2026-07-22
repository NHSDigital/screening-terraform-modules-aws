# VPC Endpoints

Thin wrapper around the community [`terraform-aws-modules/vpc/aws//modules/vpc-endpoints`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest/submodules/vpc-endpoints) submodule for creating Interface and Gateway VPC endpoints with optional per-endpoint policies, default security group assignment, and subnet customization.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| Caller-controlled security | Module does NOT create security groups; caller must create and pass them |
| Default security groups | Single `security_group_id` can default all Interface endpoints; per-endpoint override via `security_group_ids` |
| Endpoint policies | Module passes through optional policies for both Gateway (S3/DynamoDB) and Interface (SNS, SQS, etc.) endpoints; caller responsible for restrictive policies |
| Subnet isolation | Default placement in intra subnets (no internet route); can override per-endpoint |
| Consistent tagging | All resources tagged via `var.tags`; no additional tagging logic |

## What this module provides

- **Interface endpoint support** — Creates endpoints in specified subnets (default: all subnets in `var.subnet_ids`)
- **Gateway endpoint support** — Creates endpoints with route table associations (S3, DynamoDB)
- **Default security group** — Single `var.security_group_id` applies to all Interface endpoints unless overridden per-endpoint
- **Default subnets** — Single `var.subnet_ids` applies to all endpoints unless overridden per-endpoint
- **Per-endpoint overrides** — `security_group_ids`, `subnet_ids`, and `policy` customizable per endpoint
- **Per-endpoint policies** — Optional endpoint policies for both Gateway and Interface endpoints (recommended for security)
- **Consistent tagging** — All resources tagged via `var.tags`

## Usage

### Example 1: Minimal Interface endpoints with default security group

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc-endpoint?ref=v7.0.0"

  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.intra_subnet_ids
  security_group_id = aws_security_group.vpc_endpoints.id

  endpoints = {
    ecr_api = {
      service      = "ecr.api"
      service_type = "Interface"
      # Inherits security_group_id from var.security_group_id
    }

    ecr_dkr = {
      service      = "ecr.api"
      service_type = "Interface"
      # Inherits security_group_id from var.security_group_id
    }
  }

  tags = var.tags
}
```

### Example 2: Gateway endpoint (S3)

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc-endpoint?ref=v7.0.0"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.intra_subnet_ids

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      # Optional: restrictive policy to limit access
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = ["s3:GetObject", "s3:ListBucket"]
          Resource  = [
            "arn:aws:s3:::my-bucket",
            "arn:aws:s3:::my-bucket/*"
          ]
        }]
      })
    }
  }

  tags = var.tags
}
```

### Example 3: Gateway endpoint (DynamoDB)

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc-endpoint?ref=v7.0.0"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.intra_subnet_ids

  endpoints = {
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      # Restrict to specific table and actions
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = ["dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan"]
          Resource  = "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/my-table"
        }]
      })
    }
  }

  tags = var.tags
}
```

### Example 4: Interface endpoint (basic)

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc-endpoint?ref=v7.0.0"

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.intra_subnet_ids
  security_group_id = aws_security_group.interface_endpoints.id

  endpoints = {
    sns = {
      service      = "sns"
      service_type = "Interface"
      # Inherits all intra subnets (default)
      # Inherits security_group_id from var.security_group_id
    }

    sqs = {
      service      = "sqs"
      service_type = "Interface"
      # Inherits all intra subnets (default)
      # Inherits security_group_id from var.security_group_id
    }
  }

  tags = var.tags
}
```

### Example 5: Interface endpoint with user-defined IP address (static ENI placement)

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc-endpoint?ref=v7.0.0"

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.intra_subnet_ids
  security_group_id = aws_security_group.interface_endpoints.id

  endpoints = {
    ecr_api = {
      service      = "ecr.api"
      service_type = "Interface"
      # Fixed IPs in specific subnet (single AZ, lower cost)
      subnet_ids = [module.vpc.intra_subnet_ids[0]]
      private_dns_enabled = true
      # Optional: specify exact private IPs via network_interface_ids if needed
    }
  }

  tags = var.tags
}
```

### Example 6: PrivateLink to RDS with policy and security group

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc-endpoint?ref=v7.0.0"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.intra_subnet_ids

  endpoints = {
    rds = {
      service            = "rds"
      service_type       = "Interface"
      security_group_ids = [aws_security_group.rds_endpoint.id]
      private_dns_enabled = true
      # Optional: policy to restrict RDS endpoint access
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = ["rds:DescribeDBInstances", "rds:DescribeDBClusters"]
          Resource  = "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:*"
        }]
      })
    }
  }

  tags = var.tags
}

# Create RDS-specific security group (separate from generic endpoints)
resource "aws_security_group" "rds_endpoint" {
  name_prefix = "rds-endpoint-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application_tier.id]
  }
}
```

### Example 7: PrivateLink to EC2 with policy and security group

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc-endpoint?ref=v7.0.0"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.intra_subnet_ids

  endpoints = {
    ec2 = {
      service            = "ec2"
      service_type       = "Interface"
      security_group_ids = [aws_security_group.ec2_endpoint.id]
      # Optional: policy to restrict EC2 API access
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = ["ec2:DescribeInstances", "ec2:DescribeSecurityGroups"]
          Resource  = "*"
        }]
      })
    }
  }

  tags = var.tags
}

resource "aws_security_group" "ec2_endpoint" {
  name_prefix = "ec2-endpoint-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.automation_tier.id]
  }
}
```

### Example 8: PrivateLink to NLB with policy, security group, and private DNS

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc-endpoint?ref=v7.0.0"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.intra_subnet_ids

  endpoints = {
    elasticloadbalancing = {
      service              = "elasticloadbalancing"
      service_type         = "Interface"
      security_group_ids   = [aws_security_group.nlb_endpoint.id]
      private_dns_enabled  = true
      # Limit NLB API access to describe operations
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = [
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeLoadBalancerAttributes"
          ]
          Resource  = "*"
        }]
      })
    }
  }

  tags = var.tags
}

resource "aws_security_group" "nlb_endpoint" {
  name_prefix = "nlb-endpoint-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.orchestration_tier.id]
  }

  tags = {
    Name = "nlb-endpoint-sg"
  }
}
```

### Example 9: Complex: Multiple endpoint types with mixed defaults and overrides

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc-endpoint?ref=v7.0.0"

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.intra_subnet_ids
  security_group_id = aws_security_group.generic_endpoints.id  # Default for Interface endpoints

  endpoints = {
    # Gateway endpoints (no security group)
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = ["s3:GetObject"]
          Resource  = "arn:aws:s3:::my-bucket/*"
        }]
      })
    }

    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    }

    # Interface endpoints - uses default security_group_id
    ecr_api = {
      service      = "ecr.api"
      service_type = "Interface"
      # Inherits var.security_group_id and var.subnet_ids
    }

    ecr_dkr = {
      service      = "ecr.dkr"
      service_type = "Interface"
      # Inherits var.security_group_id and var.subnet_ids
    }

    # Interface endpoint - overrides security group
    secretsmanager = {
      service            = "secretsmanager"
      service_type       = "Interface"
      security_group_ids = [aws_security_group.secrets_endpoint.id]
      # Uses default subnet_ids
    }

    # Interface endpoint - overrides both security group and subnets (single AZ)
    ssm = {
      service            = "ssm"
      service_type       = "Interface"
      security_group_ids = [aws_security_group.ssm_endpoint.id]
      subnet_ids         = [module.vpc.intra_subnet_ids[0]]  # Cost optimization
    }

    # Interface endpoint - overrides everything including private DNS
    rds = {
      service              = "rds"
      service_type         = "Interface"
      security_group_ids   = [aws_security_group.rds_endpoint.id]
      subnet_ids           = slice(module.vpc.intra_subnet_ids, 0, 2)  # Two AZs for HA
      private_dns_enabled  = true
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = { AWS = data.aws_caller_identity.current.arn }
          Action    = "rds-db:connect"
          Resource  = "*"
        }]
      })
    }
  }

  tags = var.tags
}
```

## Conventions

### Security group and subnet handling

**Security groups** (Interface endpoints only):

| Scenario | Behavior |
| --- | --- |
| Endpoint specifies `security_group_ids` | Uses those (takes precedence) |
| Endpoint does NOT specify `security_group_ids` + `var.security_group_id` set | Uses `var.security_group_id` |
| Endpoint does NOT specify `security_group_ids` + `var.security_group_id = null` | **Validation error** for Interface endpoints |
| Gateway endpoint | Ignored; does not support security groups |

**Subnets** (all endpoint types):

| Scenario | Behavior |
| --- | --- |
| Endpoint specifies `subnet_ids` | Uses those (takes precedence) |
| Endpoint does NOT specify `subnet_ids` + `var.subnet_ids` set | Uses `var.subnet_ids` for all endpoints |
| Gateway endpoint with route table placement | `subnet_ids` ignored; uses `route_table_ids` instead |

### Endpoint types and required attributes

| Type | Required attributes | Optional attributes |
| --- | --- | --- |
| Interface | `service`, and either per-endpoint `security_group_ids` OR `var.security_group_id` | `subnet_ids`, `policy`, `private_dns_enabled`, `tags` |
| Gateway | `service`, `route_table_ids` | `policy`, `tags` |

### Naming and variable precedence

This module is a pass-through wrapper with no complex naming logic. The caller is responsible for:

- **Endpoint logical names**: Use clear, descriptive keys in the `endpoints` map (e.g., `ecr_api`, `s3`, `secretsmanager`)
- **Service names**: AWS service names (e.g., `s3`, `ecr.api`, `ecr.dkr`) are passed directly to the upstream module
- **Subnet placement**: Default to `intra_subnet_ids` (no internet route); override per-endpoint via `subnet_ids` for cost optimization

### Caller responsibilities

This module does **NOT** create:

- **Security groups** — Create these at the stack level and pass `security_group_ids` per-endpoint or `var.security_group_id` as default
- **Subnets** — Caller must provide `var.subnet_ids` (default placement) and per-endpoint `subnet_ids` overrides
- **Endpoint policies** — Caller must supply if access restriction is needed (default: open to all principals)
- **Route tables** — For Gateway endpoints, pass existing route table IDs
- **IAM policies** — Caller owns any IAM permissions to consume the endpoints

### AWS service names by endpoint type

**Interface endpoints** (most AWS services):

- Container services: `ecr.api`, `ecr.dkr`
- Secrets: `secretsmanager`, `ssm`
- SNS/SQS: `sns`, `sqs`
- CloudWatch: `logs`, `monitoring`
- Many others; see [AWS documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-service.html)

**Gateway endpoints** (only):

- `s3`
- `dynamodb`

## Security Considerations

### Endpoint policies (Gateway endpoints only: S3, DynamoDB)

**Gateway endpoints** (S3, DynamoDB) support endpoint policies to restrict access. **By default, VPC endpoints allow ALL principals and actions.** This is a significant security risk in most deployments. Always supply restrictive `policy` attributes for Gateway endpoints:

```hcl
endpoints = {
  s3 = {
    service  = "s3"
    service_type = "Gateway"
    route_table_ids = module.vpc.private_route_table_ids
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "arn:aws:s3:::my-bucket/*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = var.organization_id
          }
        }
      }]
    })
  }
}
```

Without policies, any IAM principal in your account (or federated users) can access any S3 bucket or service through the endpoint.

**Interface endpoints do NOT support policies.** Instead, they use security groups for access control (see below).

### Security groups for Interface endpoints

Interface endpoints require security groups to:

- Restrict source IP ranges (e.g., only from specific security groups or subnets)
- Restrict ports and protocols

**Best practice**: Create dedicated security groups per endpoint service rather than sharing a single group:

```hcl
resource "aws_security_group" "ecr_endpoints" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.container_workloads.id]
  }
}

resource "aws_security_group" "secrets_endpoints" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.application_tier.id]
  }
}
```

### Subnet placement

- **Intra subnets (default)**: No internet route; isolated and secure for sensitive services
- **Private subnets**: Internet route through NAT; appropriate if endpoints serve public internet access needs
- **Per-endpoint override**: Use sparingly; document the reason for non-default subnet placement

## What this module does NOT do

- **Does NOT create security groups** — You must create security groups at the stack level and pass them
- **Does NOT create IAM policies** — IAM permissions to consume endpoints are the caller's responsibility
- **Does NOT enforce endpoint policies** — Endpoints default to open access; you must supply restrictive policies
- **Does NOT manage route table associations** — For Gateway endpoints, you pass existing route tables
- **Does NOT apply custom naming or labels** — Service/endpoint names are passed through as-is
- **Does NOT create DNS records** — Private DNS for Interface endpoints is configured via `private_dns_enabled`; caller owns Route53 setup if needed
- **Does NOT manage VPCs or subnets** — Caller must provide `vpc_id` and `subnet_ids` from the VPC module

## Troubleshooting

### "Duplicate security group" error

Ensure you're creating security groups **outside** the endpoints module:

```hcl
# ✓ Correct: security group created separately, passed to module
resource "aws_security_group" "vpc_endpoints" {
  vpc_id = module.vpc.vpc_id
}

module "vpc_endpoints" {
  endpoints = {
    ecr_api = {
      service            = "ecr.api"
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
  }
}
```

### "Endpoint not available" error

For Gateway endpoints (S3, DynamoDB), ensure route tables include a route to the endpoint:

```hcl
endpoints = {
  s3 = {
    service         = "s3"
    service_type    = "Gateway"
    route_table_ids = [module.vpc.private_route_table_ids[0]]
  }
}
```

### "Permission denied" when using endpoints

If you can't access services via endpoints, verify:

1. **Endpoint policy** — If set, does it allow your IAM principal and action?
2. **Security group** — Are inbound rules permissive enough (port 443 for HTTPS)?
3. **DNS** — Is `private_dns_enabled = true` so DNS resolves to the endpoint?

## References

- [AWS VPC Endpoints documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [Interface vs Gateway endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpce-interface.html)
- [Endpoint policy examples](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-access.html)
- [Upstream module documentation](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/modules/vpc-endpoints)

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 6.6.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | Map of VPC endpoints to create. Each key is a logical name,<br/>each value is passed through to the upstream vpc-endpoints submodule.<br/><br/>**Interface endpoints** (default):<br/>  - Placed in intra subnets by default (can override via subnet\_ids)<br/>  - Require security\_group\_ids<br/>  - Support optional private\_dns\_enabled (default true)<br/><br/>**Gateway endpoints**:<br/>  - Must specify service\_type = "Gateway"<br/>  - Require route\_table\_ids<br/>  - Do NOT use security\_group\_ids or subnet\_ids<br/><br/>Supported per-endpoint attributes:<br/>  service              - AWS service name (e.g. "s3", "ecr.api") [REQUIRED]<br/>  service\_type         - "Interface" (default) or "Gateway"<br/>  policy               - JSON endpoint policy document (optional but recommended)<br/>  subnet\_ids           - Override default intra subnets (optional; Interface only)<br/>  security\_group\_ids   - Security group IDs (required for Interface endpoints)<br/>  private\_dns\_enabled  - Enable private DNS (Interface only; default true)<br/>  route\_table\_ids      - Route table IDs (required for Gateway endpoints)<br/>  tags                 - Per-endpoint tags (optional)<br/><br/>**Security consideration:** Endpoint policies restrict access. If not specified,<br/>the endpoint allows all principals. Recommended to set restrictive policies. | `any` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Default security group ID to associate with Interface endpoints. Per-endpoint security\_group\_ids override this default. Can be null if all Interface endpoints specify security\_group\_ids explicitly. | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs to use as default for Interface endpoints (recommended: intra subnets with no internet route). Can be overridden per-endpoint via subnet\_ids in the endpoints map. | `list(string)` | n/a | yes |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC where endpoints will be created. | `string` | n/a | yes |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Map of VPC endpoints created, keyed by logical name. Contains all endpoint attributes (id, arn, network\_interface\_ids, subnet\_ids, security\_groups, etc.). |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | Map of security groups associated with endpoints. Only populated if upstream module created security groups (not applicable to this wrapper, which sets create\_security\_group=false). |
| <a name="output_validate_endpoint_policies"></a> [validate\_endpoint\_policies](#output\_validate\_endpoint\_policies) | Informational: Policy coverage for Gateway endpoints. Both Gateway and Interface endpoints support policies; Gateway endpoints (S3, DynamoDB) should have restrictive policies as a security best practice. |
| <a name="output_validate_endpoints_not_empty"></a> [validate\_endpoints\_not\_empty](#output\_validate\_endpoints\_not\_empty) | Informational: Confirms endpoints are specified |
| <a name="output_validate_gateway_endpoint_config"></a> [validate\_gateway\_endpoint\_config](#output\_validate\_gateway\_endpoint\_config) | Validation status: Ensures Gateway endpoints have route\_table\_ids and do not have security\_group\_ids |
| <a name="output_validate_security_group_coverage"></a> [validate\_security\_group\_coverage](#output\_validate\_security\_group\_coverage) | Validation status: Ensures Interface endpoints have security group coverage (either per-endpoint security\_group\_ids or module-level var.security\_group\_id as default) |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
