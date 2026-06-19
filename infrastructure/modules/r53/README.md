# r53

Creates Route53 hosted zones, Route53 Resolver endpoints, and Route53
Resolver DNS Firewall rule groups for screening shared-resource stacks.
This is a thin screening wrapper around the community
[`terraform-aws-modules/route53/aws`](https://registry.terraform.io/modules/terraform-aws-modules/route53/aws/latest)
module set, with naming and tagging supplied by the central `tags` module via
`context.tf`.

## What this module enforces

|Control|How it is enforced|
|-|-|
|Creation gate|All `for_each` resource maps are set to `{}` when `module.this.enabled = false`, preventing any resource creation|
|Context-derived naming and tagging|All resources inherit `module.this.tags`; resolver endpoint and firewall rule group names default to context-derived values|
|Firewall domain list de-duplication|Standalone `aws_route53_resolver_firewall_rule` resources are used for external/aws-managed firewall domain lists to prevent orphan empty domain lists|
|Per-item tag merging|Each resource merges `module.this.tags` with per-item `tags`, ensuring standard tags can never be stripped by a caller|

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
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.51.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_hosted_zones"></a> [hosted\_zones](#module\_hosted\_zones) | terraform-aws-modules/route53/aws | 6.5.0 |
| <a name="module_resolver_endpoint_label"></a> [resolver\_endpoint\_label](#module\_resolver\_endpoint\_label) | ../tags | n/a |
| <a name="module_resolver_endpoints"></a> [resolver\_endpoints](#module\_resolver\_endpoints) | terraform-aws-modules/route53/aws//modules/resolver-endpoint | 6.5.0 |
| <a name="module_resolver_firewall_association_label"></a> [resolver\_firewall\_association\_label](#module\_resolver\_firewall\_association\_label) | ../tags | n/a |
| <a name="module_resolver_firewall_rule_group_label"></a> [resolver\_firewall\_rule\_group\_label](#module\_resolver\_firewall\_rule\_group\_label) | ../tags | n/a |
| <a name="module_resolver_firewall_rule_groups"></a> [resolver\_firewall\_rule\_groups](#module\_resolver\_firewall\_rule\_groups) | terraform-aws-modules/route53/aws//modules/resolver-firewall-rule-group | 6.5.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_route53_resolver_firewall_rule.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule) | resource |
| [aws_route53_resolver_firewall_rule_group_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule_group_association) | resource |

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
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_hosted_zones"></a> [hosted\_zones](#input\_hosted\_zones) | Map of hosted zones to create or adopt.<br/><br/>Each key is a logical identifier used only in Terraform state and outputs.<br/>Each value forwards to the upstream `terraform-aws-modules/route53/aws`<br/>root module.<br/><br/>`name` is the DNS zone name (for example `example.internal` or<br/>`example.nhs.uk`) and is required. | <pre>map(object({<br/>    name                        = string<br/>    create                      = optional(bool, true)<br/>    create_zone                 = optional(bool, true)<br/>    private_zone                = optional(bool, false)<br/>    vpc_id                      = optional(string)<br/>    comment                     = optional(string)<br/>    delegation_set_id           = optional(string)<br/>    force_destroy               = optional(bool)<br/>    enable_accelerated_recovery = optional(bool)<br/>    ignore_vpc                  = optional(bool, false)<br/>    vpc = optional(map(object({<br/>      vpc_id     = string<br/>      vpc_region = optional(string)<br/>    })))<br/>    vpc_association_authorizations = optional(map(object({<br/>      vpc_id     = string<br/>      vpc_region = optional(string)<br/>    })))<br/>    enable_dnssec               = optional(bool, false)<br/>    create_dnssec_kms_key       = optional(bool, true)<br/>    dnssec_kms_key_arn          = optional(string)<br/>    dnssec_kms_key_description  = optional(string)<br/>    dnssec_kms_key_aliases      = optional(list(string), [])<br/>    dnssec_kms_key_tags         = optional(map(string), {})<br/>    dnssec_key_signing_key_name = optional(string)<br/>    records                     = optional(any, {})<br/>    tags                        = optional(map(string), {})<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
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
| <a name="input_resolver_endpoints"></a> [resolver\_endpoints](#input\_resolver\_endpoints) | Map of Route53 Resolver endpoints to create.<br/><br/>Each key is a logical identifier used in Terraform state and outputs.<br/>Names default to a context-derived value when `name` is omitted. | <pre>map(object({<br/>    create    = optional(bool, true)<br/>    region    = optional(string)<br/>    name      = optional(string)<br/>    direction = optional(string, "INBOUND")<br/>    type      = optional(string)<br/>    protocols = optional(list(string), ["Do53"])<br/>    ip_address = optional(list(object({<br/>      ip        = optional(string)<br/>      ipv6      = optional(string)<br/>      subnet_id = string<br/>    })), [])<br/>    security_group_ids             = optional(list(string), [])<br/>    create_security_group          = optional(bool, true)<br/>    security_group_name            = optional(string)<br/>    security_group_use_name_prefix = optional(bool, false)<br/>    security_group_description     = optional(string)<br/>    vpc_id                         = optional(string)<br/>    security_group_ingress_rules = optional(map(object({<br/>      name                         = optional(string)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      description                  = optional(string)<br/>      prefix_list_id               = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      tags                         = optional(map(string), {})<br/>    })), {})<br/>    security_group_egress_rules = optional(map(object({<br/>      name                         = optional(string)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      description                  = optional(string)<br/>      prefix_list_id               = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      tags                         = optional(map(string), {})<br/>    })), {})<br/>    security_group_tags = optional(map(string), {})<br/>    rules = optional(map(object({<br/>      domain_name = string<br/>      name        = optional(string)<br/>      rule_type   = string<br/>      tags        = optional(map(string), {})<br/>      target_ip = optional(list(object({<br/>        ip       = string<br/>        ipv6     = optional(string)<br/>        port     = optional(number)<br/>        protocol = optional(string)<br/>      })))<br/>      vpc_id = optional(string)<br/>    })), {})<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_resolver_firewall_rule_groups"></a> [resolver\_firewall\_rule\_groups](#input\_resolver\_firewall\_rule\_groups) | Map of Route53 Resolver DNS Firewall rule groups to create.<br/><br/>Each rule can either create a dedicated firewall domain list via `domains`<br/>or reference an existing one via `firewall_domain_list_id`. | <pre>map(object({<br/>    create = optional(bool, true)<br/>    region = optional(string)<br/>    name   = optional(string)<br/>    ram_resource_associations = optional(map(object({<br/>      resource_share_arn = string<br/>    })), {})<br/>    vpc_ids  = optional(map(string), {})<br/>    priority = optional(number, 100)<br/>    rules = optional(map(object({<br/>      name                               = optional(string)<br/>      domains                            = optional(list(string))<br/>      action                             = string<br/>      block_override_dns_type            = optional(string)<br/>      block_override_domain              = optional(string)<br/>      block_override_ttl                 = optional(number)<br/>      block_response                     = optional(string)<br/>      firewall_domain_list_id            = optional(string)<br/>      firewall_domain_redirection_action = optional(string)<br/>      priority                           = number<br/>      q_type                             = optional(string)<br/>      tags                               = optional(map(string), {})<br/>    })), {})<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_hosted_zone_arns"></a> [hosted\_zone\_arns](#output\_hosted\_zone\_arns) | Map of hosted zone key -> Route53 hosted zone ARN. |
| <a name="output_hosted_zone_ids"></a> [hosted\_zone\_ids](#output\_hosted\_zone\_ids) | Map of hosted zone key -> Route53 hosted zone ID. |
| <a name="output_hosted_zone_name_servers"></a> [hosted\_zone\_name\_servers](#output\_hosted\_zone\_name\_servers) | Map of hosted zone key -> authoritative name servers. |
| <a name="output_hosted_zone_names"></a> [hosted\_zone\_names](#output\_hosted\_zone\_names) | Map of hosted zone key -> Route53 hosted zone name. |
| <a name="output_hosted_zone_records"></a> [hosted\_zone\_records](#output\_hosted\_zone\_records) | Map of hosted zone key -> records created in the zone. |
| <a name="output_resolver_endpoint_arns"></a> [resolver\_endpoint\_arns](#output\_resolver\_endpoint\_arns) | Map of resolver endpoint key -> endpoint ARN. |
| <a name="output_resolver_endpoint_created_security_group_ids"></a> [resolver\_endpoint\_created\_security\_group\_ids](#output\_resolver\_endpoint\_created\_security\_group\_ids) | Map of resolver endpoint key -> created security group ID. |
| <a name="output_resolver_endpoint_host_vpc_ids"></a> [resolver\_endpoint\_host\_vpc\_ids](#output\_resolver\_endpoint\_host\_vpc\_ids) | Map of resolver endpoint key -> host VPC ID. |
| <a name="output_resolver_endpoint_ids"></a> [resolver\_endpoint\_ids](#output\_resolver\_endpoint\_ids) | Map of resolver endpoint key -> endpoint ID. |
| <a name="output_resolver_endpoint_ip_addresses"></a> [resolver\_endpoint\_ip\_addresses](#output\_resolver\_endpoint\_ip\_addresses) | Map of resolver endpoint key -> endpoint IP addresses. |
| <a name="output_resolver_endpoint_rules"></a> [resolver\_endpoint\_rules](#output\_resolver\_endpoint\_rules) | Map of resolver endpoint key -> resolver rules created by that endpoint module. |
| <a name="output_resolver_endpoint_security_group_arns"></a> [resolver\_endpoint\_security\_group\_arns](#output\_resolver\_endpoint\_security\_group\_arns) | Map of resolver endpoint key -> created security group ARN. |
| <a name="output_resolver_endpoint_security_group_ids"></a> [resolver\_endpoint\_security\_group\_ids](#output\_resolver\_endpoint\_security\_group\_ids) | Map of resolver endpoint key -> attached security group IDs. |
| <a name="output_resolver_firewall_rule_group_arns"></a> [resolver\_firewall\_rule\_group\_arns](#output\_resolver\_firewall\_rule\_group\_arns) | Map of firewall rule group key -> rule group ARN. |
| <a name="output_resolver_firewall_rule_group_domain_lists"></a> [resolver\_firewall\_rule\_group\_domain\_lists](#output\_resolver\_firewall\_rule\_group\_domain\_lists) | Map of firewall rule group key -> domain lists created in that group. |
| <a name="output_resolver_firewall_rule_group_ids"></a> [resolver\_firewall\_rule\_group\_ids](#output\_resolver\_firewall\_rule\_group\_ids) | Map of firewall rule group key -> rule group ID. |
| <a name="output_resolver_firewall_rule_group_ram_resource_associations"></a> [resolver\_firewall\_rule\_group\_ram\_resource\_associations](#output\_resolver\_firewall\_rule\_group\_ram\_resource\_associations) | Map of firewall rule group key -> RAM resource associations created for that group. |
| <a name="output_resolver_firewall_rule_group_rules"></a> [resolver\_firewall\_rule\_group\_rules](#output\_resolver\_firewall\_rule\_group\_rules) | Map of firewall rule group key -> firewall rules created in that group. |
| <a name="output_resolver_firewall_rule_group_share_statuses"></a> [resolver\_firewall\_rule\_group\_share\_statuses](#output\_resolver\_firewall\_rule\_group\_share\_statuses) | Map of firewall rule group key -> RAM share status. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
