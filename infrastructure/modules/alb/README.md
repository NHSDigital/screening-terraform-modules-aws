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
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | 10.5.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_logs"></a> [access\_logs](#input\_access\_logs) | S3 access log delivery configuration. When null, access logging is disabled. | <pre>object({<br/>    bucket  = string<br/>    prefix  = optional(string)<br/>    enabled = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | When true, deletion protection is enabled on the load balancer. Set to false for non-production environments where the load balancer needs to be freely destroyed. | `bool` | `true` | no |
| <a name="input_enable_http_https_redirect"></a> [enable\_http\_https\_redirect](#input\_enable\_http\_https\_redirect) | When true, automatically adds a port-80 HTTP-to-HTTPS (301) redirect listener. Only applies when load\_balancer\_type is 'application'. Set to false if you are defining your own HTTP listener or the ALB is not serving HTTPS traffic. | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | When true, the load balancer is internal (private). When false, it is internet-facing. Defaults to false. | `bool` | `false` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | Map of listener configurations to create. Passed directly to the upstream module.<br/>For ALB, define HTTPS and HTTP listeners here. For NLB, define TCP/TLS listeners.<br/>See https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest<br/>for full schema documentation. | `any` | `{}` | no |
| <a name="input_load_balancer_type"></a> [load\_balancer\_type](#input\_load\_balancer\_type) | Type of load balancer to create. Either 'application' (ALB) or 'network' (NLB). | `string` | `"application"` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_security_group_egress_rules"></a> [security\_group\_egress\_rules](#input\_security\_group\_egress\_rules) | Map of egress rules to add to the load balancer security group.<br/>Example:<br/>  security\_group\_egress\_rules = {<br/>    https\_out = {<br/>      from\_port   = 443<br/>      to\_port     = 443<br/>      ip\_protocol = "tcp"<br/>      cidr\_ipv4   = "0.0.0.0/0"<br/>    }<br/>  } | `any` | `{}` | no |
| <a name="input_security_group_ingress_rules"></a> [security\_group\_ingress\_rules](#input\_security\_group\_ingress\_rules) | Map of ingress rules to add to the load balancer security group.<br/>Each key is a logical name; each value is an object describing the rule.<br/>Example:<br/>  security\_group\_ingress\_rules = {<br/>    https = {<br/>      from\_port   = 443<br/>      to\_port     = 443<br/>      ip\_protocol = "tcp"<br/>      description = "HTTPS from internet"<br/>      cidr\_ipv4   = "0.0.0.0/0"<br/>    }<br/>  } | `any` | `{}` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet IDs to attach to the load balancer. For internet-facing ALBs, use public subnets. | `list(string)` | n/a | yes |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | Map of target group configurations to create. Passed directly to the upstream module.<br/>See https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest<br/>for full schema documentation. | `any` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to this module path. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which the load balancer security group will be created. | `string` | n/a | yes |
| <a name="input_web_acl_arn"></a> [web\_acl\_arn](#input\_web\_acl\_arn) | ARN of a WAFv2 Web ACL to associate with the load balancer. Only valid for ALB. When null, no WAF association is created. | `string` | `null` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the load balancer. Used by WAF to associate a Web ACL. |
| <a name="output_arn_suffix"></a> [arn\_suffix](#output\_arn\_suffix) | ARN suffix of the load balancer. Used with CloudWatch metrics. |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | DNS name of the load balancer. Used by Route53 alias records. |
| <a name="output_id"></a> [id](#output\_id) | ID of the load balancer (same as ARN). |
| <a name="output_listeners"></a> [listeners](#output\_listeners) | Map of listeners created and their attributes. ECS tasks use this for depends\_on. |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the security group created for the load balancer. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group created for the load balancer. |
| <a name="output_target_groups"></a> [target\_groups](#output\_target\_groups) | Map of target groups created and their attributes. ECS tasks reference target\_group ARNs from here. |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Hosted zone ID of the load balancer. Used by Route53 alias records. |
<!-- END_TF_DOCS -->
<!-- markdownlint-enable -->
<!-- vale on -->
