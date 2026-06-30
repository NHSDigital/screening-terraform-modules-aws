# Security-Group

NHS Screening wrapper around the community
[`terraform-aws-modules/security-group/aws`][1]
module that consumes the shared `context.tf` for naming and tagging.

[1]: https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest

The name of the security group will have a random suffix. This enables
replacements to happen without dropping traffic, as terraform can create
the replacement before destroying the original.

## What this module enforces

|Control|How it is enforced|
|---|---|
|Naming consistency|`name = module.this.id` and `tags = module.this.tags`|
|Creation gate|`create = module.this.enabled`|
|Exclusive rules|`enable_exclusive_rules = true` by default|

## Usage

### Minimal: create a security group in a VPC

```hcl
module "app_sg" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-group?ref=<tag>"

  service     = "bcss"
  project     = "api"
  environment = "prod"
  name        = "app"

  description = "Security group for the screening API"
  vpc_id      = module.vpc.vpc_id
}
```

### Allow traffic between members of the security group

```hcl
module "app_sg" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-group?ref=<tag>"

  service     = "bcss"
  project     = "api"
  environment = "prod"
  name        = "app"

  description = "Security group for the screening API"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    self-all = {
      ip_protocol                  = "-1"
      referenced_security_group_id = "self"  # rewritten to the security group's own id at apply time
      description                  = "All traffic from members of this SG"
    }
  }
```

### Ingress from a load balancer security group

```hcl
module "app_sg" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-group?ref=<tag>"

  service     = "bcss"
  project     = "api"
  environment = "prod"
  name        = "app"

  description = "Only allow HTTPS from the ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    alb_https = {
      ip_protocol                  = "tcp"
      from_port                    = 443
      to_port                      = 443
      referenced_security_group_id = module.alb_sg.security_group_id
      description                  = "HTTPS from ALB"
    }
  }
}
```

### Restrict egress to HTTPS only

```hcl
module "app_sg" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-group?ref=<tag>"

  service     = "bcss"
  project     = "api"
  environment = "prod"
  name        = "app"

  description = "Limit outbound traffic to HTTPS"
  vpc_id      = module.vpc.vpc_id

  egress_rules = {
    https_out = {
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTPS egress only"
    }
  }
}
```

### IPv6 example: allow documentation-only ranges

```hcl
module "ipv6_app_sg" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-group?ref=<tag>"

  service     = "bcss"
  project     = "api"
  environment = "prod"
  name        = "ipv6-app"

  description = "IPv6 example using documentation prefixes"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    # RFC9637 documentation prefix example (3fff::/20)
    app_from_docs_ipv6 = {
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv6   = "3fff:0f00:1234:5678::/64"
      description = "HTTPS from a narrow RFC9637 documentation subnet"
    }
  }

  egress_rules = {
    # RFC3849 documentation prefix example (2001:db8::/32)
    app_to_docs_ipv6 = {
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv6   = "2001:db8:abcd:ef01::/64"
      description = "HTTPS egress to a narrow RFC3849 documentation range"
    }
  }
}
```

### Complex: database with multiple rule types (single IP, CIDR range, prefix list, security group)

```hcl
module "database_sg" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-group?ref=<tag>"

  service     = "bcss"
  project     = "data"
  environment = "prod"
  name        = "postgres-db"

  description = "PostgreSQL database with complex access rules"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    # Single IP address (admin access)
    admin_direct = {
      ip_protocol = "tcp"
      from_port   = 5432
      to_port     = 5432
      # RFC5737 TEST-NET-3 example address (safe dummy value)
      cidr_ipv4   = "203.0.113.5/32"
      description = "Direct PostgreSQL from admin workstation"
    }

    # Range of IPs (office network)
    office_network = {
      ip_protocol = "tcp"
      from_port   = 5432
      to_port     = 5432
      cidr_ipv4   = "10.1.0.0/16"
      description = "PostgreSQL from office network"
    }

    # AWS managed prefix list (e.g., S3 gateway endpoint)
    s3_via_gateway = {
      ip_protocol    = "tcp"
      from_port      = 443
      to_port        = 443
      prefix_list_id = "pl-12345678"
      description    = "HTTPS to S3 via VPC gateway endpoint"
    }

    # Referenced security group (app servers)
    from_app_servers = {
      ip_protocol                  = "tcp"
      from_port                    = 5432
      to_port                      = 5432
      referenced_security_group_id = module.app_sg.security_group_id
      description                  = "PostgreSQL from application tier"
    }
  }

  egress_rules = {
    # Outbound to external database replication
    replication_out = {
      ip_protocol = "tcp"
      from_port   = 5432
      to_port     = 5432
      # RFC5737 TEST-NET-1 example range (safe dummy value)
      cidr_ipv4   = "192.0.2.0/24"
      description = "PostgreSQL replication to standby"
    }

    # DNS queries
    dns_out = {
      ip_protocol = "udp"
      from_port   = 53
      to_port     = 53
      # 0.0.0.0/0 intentionally shown as "whole world" example traffic scope
      cidr_ipv4   = "0.0.0.0/0"
      description = "DNS resolution"
    }

    # Egress to monitoring stack (referenced security group)
    to_monitoring = {
      ip_protocol                  = "tcp"
      from_port                    = 443
      to_port                      = 443
      referenced_security_group_id = module.monitoring_sg.security_group_id
      description                  = "Metrics export to monitoring"
    }
  }
}
```

## Conventions

* Keep `ingress_rules` and `egress_rules` keys stable (for example `alb_https`,
  `db_5432`) so Terraform can track rule resources predictably over time.
* Prefer `referenced_security_group_id` over broad CIDR ranges when traffic is
  between AWS-managed components.
* Set `description` to explain intent, not just protocol/port, so operators can
  understand why a rule exists from the AWS console.
* Use `context.enabled = false` to disable creation in environments where the
  security group is not required.

## Common rule presets (avoiding port duplication)

To avoid duplicating port ranges and protocol definitions across multiple security groups, define common rule templates as locals in your Terraform stack. This keeps your code DRY and maintainable.

### Reference: upstream module port ranges

The upstream `terraform-aws-modules/security-group/aws` module provides comprehensive rule presets in its [`modules/`](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/modules) directory (e.g., `modules/http-80`, `modules/https-443`, `modules/mysql`, etc.). You can reference these for authoritative port ranges:

1. Browse [`github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/modules`](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/modules)
2. Check the relevant module (e.g., `modules/postgresql/main.tf`) to see the port definitions
3. Copy the port ranges and protocols into your stack's rule presets

**Example:** To find the standard port for PostgreSQL, check [`modules/postgresql/main.tf`](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/modules/postgresql) in the upstream repo and extract the port number (5432 for TCP).

### Defining and using rule presets in your stack

In your consumer stack (e.g., `bcss` repository), define rule templates as locals:

```hcl
locals {
  # Common rule presets to reuse across security groups
  # Reference: https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/modules
  rules_http = {
    http = {
      ip_protocol = "tcp"
      from_port   = 80
      to_port     = 80
      description = "HTTP"
    }
  }

  rules_https = {
    https = {
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      description = "HTTPS"
    }
  }

  rules_http_https = merge(local.rules_http, local.rules_https)

  rules_ssh = {
    ssh = {
      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22
      description = "SSH"
    }
  }

  rules_dns = {
    dns_tcp = {
      ip_protocol = "tcp"
      from_port   = 53
      to_port     = 53
      description = "DNS (TCP)"
    }
    dns_udp = {
      ip_protocol = "udp"
      from_port   = 53
      to_port     = 53
      description = "DNS (UDP)"
    }
  }

  rules_postgresql = {
    postgresql = {
      ip_protocol = "tcp"
      from_port   = 5432
      to_port     = 5432
      description = "PostgreSQL"
    }
  }

  rules_mysql = {
    mysql = {
      ip_protocol = "tcp"
      from_port   = 3306
      to_port     = 3306
      description = "MySQL"
    }
  }
}
```

Then reference these locals when creating security groups:

```hcl
module "web_sg" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/security-group?ref=<tag>"

  service     = "bcss"
  project     = "web"
  environment = "prod"
  name        = "web-tier"

  description = "Web tier with HTTP and HTTPS"
  vpc_id      = module.vpc.vpc_id

  # Merge preset rules with custom rules
  ingress_rules = merge(
    local.rules_http_https,
    {
      ssh_from_admin = {
        ip_protocol = "tcp"
        from_port   = 22
        to_port     = 22
        # RFC5737 TEST-NET-3 example range (safe dummy value)
        cidr_ipv4   = "203.0.113.0/24"
        description = "SSH from admin network"
      }
    }
  )

  egress_rules = merge(
    local.rules_https,
    local.rules_dns,
  )
}
```

This pattern keeps rule definitions in your own codebase where they can be versioned and reused across all your security groups. Store these locals in a shared file (e.g., `infrastructure/security_group_rules.tf`) so all your security group modules can reference them.

## What this module does NOT do

* Create or manage the VPC itself. Pass an existing VPC ID via `vpc_id`, or
  leave as the default `null` to use the region's default VPC.
* Infer or inject platform-standard ingress/egress rules. All traffic policy is
  caller-defined.
* Attach network ACLs, route tables, WAFs, or firewall policies.
* Manage references from compute resources (ECS services, Lambdas, RDS, etc.)
  to this security group. Consumers must wire those associations directly.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.29 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-aws-modules/security-group/aws | 6.0.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

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
| <a name="input_description"></a> [description](#input\_description) | Description for the security group | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | Map of egress rules to add to the security group | <pre>map(object({<br/>    name                         = optional(string)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    from_port                    = optional(number)<br/>    ip_protocol                  = optional(string, "tcp")<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>    to_port                      = optional(number)<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_exclusive_rules"></a> [enable\_exclusive\_rules](#input\_enable\_exclusive\_rules) | Whether to enforce that only the rules declared by this module exist on the security group. When true, out-of-band rules added via the AWS console or other Terraform configurations will be reverted on next apply | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | Map of ingress rules to add to the security group | <pre>map(object({<br/>    name                         = optional(string)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    from_port                    = optional(number)<br/>    ip_protocol                  = optional(string, "tcp")<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>    to_port                      = optional(number)<br/>  }))</pre> | `{}` | no |
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
| <a name="input_revoke_rules_on_delete"></a> [revoke\_rules\_on\_delete](#input\_revoke\_rules\_on\_delete) | Whether to revoke all rules on the security group when it is deleted. This is useful for security groups that are shared across multiple resources, as it prevents orphaned rules from remaining after the security group is deleted. | `bool` | `false` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name of security group | `string` | `""` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_use_name_prefix"></a> [use\_name\_prefix](#input\_use\_name\_prefix) | Whether to use the name (`name`) as a prefix, appending a random suffix | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the security group is created; defaults to the region's default VPC | `string` | `null` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | The ARN of the security group |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The ID of the security group |
| <a name="output_security_group_name"></a> [security\_group\_name](#output\_security\_group\_name) | The name of the security group |
| <a name="output_security_group_owner_id"></a> [security\_group\_owner\_id](#output\_security\_group\_owner\_id) | The owner ID |
| <a name="output_security_group_vpc_id"></a> [security\_group\_vpc\_id](#output\_security\_group\_vpc\_id) | The ID of the VPC used by the security group |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
