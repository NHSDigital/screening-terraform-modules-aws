# AWS Application / Network Load Balancer Terraform module

Thin NHS wrapper around [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws) that enforces the screening platform's baseline controls.

## What this module enforces

| Setting | Value | Reason |
|---|---|---|
| `create_security_group` | `false` (hardcoded) | Callers **must** pre-create and supply security groups explicitly, enforcing deliberate ingress/egress rule design |
| `drop_invalid_header_fields` | `true` (ALB only) | Prevents HTTP header injection attacks on Application Load Balancers |
| `enable_deletion_protection` | `true` (default) | Prevents accidental deletion in production; set to `false` for non-production only |
| `desync_mitigation_mode` | `defensive` (default for ALB) | Mitigates HTTP request smuggling attacks; set to `strictest` for highest security |
| `xff_header_processing_mode` | `append` (default for ALB) | Controls how X-Forwarded-For headers are handled to prevent spoofing |

| Access logs for internet-facing | Strongly recommended via validation | Internet-facing ALBs/NLBs should log to S3 for security compliance and auditing |
| HTTPS listeners require certificate | Enforced at apply time | All HTTPS/TLS listeners must provide `certificate_arn`; HTTP listeners use automatic redirect |

## What this module does NOT do

- **Does not create security groups.** Callers must define security groups and pass IDs via `var.security_groups`. This enforces explicit security group management and prevents accidental exposure.
- **Does not validate listener/target group definitions.** Callers define listeners and target groups directly. HTTPS and TLS listeners **must** include `certificate_arn` in their configuration. HTTP listeners automatically redirect to HTTPS if `enable_http_https_redirect = true` (default).
- **Does not manage certificates.** Supply your own ACM certificate ARNs in listener definitions for any HTTPS/TLS protocol listeners.
- **Does not create Route53 DNS records.** Use the [r53 module](../../modules/r53) with the ALB's `dns_name` and `zone_id` outputs to create DNS aliases pointing to the load balancer.

## Usage Examples

### 1. Internet-facing ALB with HTTPS (Minimal)

```hcl
# 1. Create security group with explicit rules
resource "aws_security_group" "alb" {
  name_prefix = "alb-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP from internet — auto-redirected to HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS from internet"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all outbound traffic to targets"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.this.tags
}

# 2. Create the ALB, passing the security group
module "alb" {
  source = "../../modules/alb"

  context     = module.this.context
  stack       = "web"
  name        = "bcss-web"
  label_order = ["service", "environment", "stack", "name"]

  load_balancer_type = "application"
  internal           = false
  vpc_id             = data.aws_vpc.selected.id
  subnets            = data.aws_subnets.public.ids

  # REQUIRED: pass pre-created security groups
  security_groups = [aws_security_group.alb.id]

  # Automatic HTTP → HTTPS redirect enabled by default
  enable_http_https_redirect = true

  # Define only HTTPS listener; HTTP redirect is automatic
  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.aws_acm_certificate.selected.arn
      forward         = {
        target_groups = ["app"]
      }
    }
  }

  target_groups = {
    app = {
      name_prefix = "app-"
      protocol    = "HTTP"
      port        = 8080
      target_type = "ip"

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        path                = "/"
        matcher             = "200-399"
      }
    }
  }

  enable_deletion_protection = true

  tags = module.this.tags
}
```

### 2. Internal ALB for ECS microservices

```hcl
resource "aws_security_group" "internal_alb" {
  name_prefix = "internal-alb-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    description     = "HTTP from VPC"
    cidr_blocks     = [data.aws_vpc.selected.cidr_block]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    description     = "HTTPS from VPC"
    cidr_blocks     = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all outbound"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.this.tags
}

module "internal_alb" {
  source = "../../modules/alb"

  context = module.this.context
  name    = "microservices"

  load_balancer_type = "application\"
  internal           = true  # Internal (private) ALB
  vpc_id             = data.aws_vpc.selected.id
  subnets            = data.aws_subnets.private.ids

  security_groups = [aws_security_group.internal_alb.id]

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.aws_acm_certificate.internal.arn
      default_action  = {
        type             = "forward"
        target_group_key = "api"
      }
      rules = [
        {
          priority = 10
          conditions = [
            {
              path_pattern = {
                values = ["/api/*"]
              }
            }
          ]
          actions = [
            {
              type             = "forward"
              target_group_key = "api"
            }
          ]
        },
        {
          priority = 20
          conditions = [
            {
              path_pattern = {
                values = ["/admin/*"]
              }
            }
          ]
          actions = [
            {
              type             = "forward"
              target_group_key = "admin"
            }
          ]
        }
      ]
    }
  }

  target_groups = {
    api = {
      name_prefix = "api-"
      protocol    = "HTTP"
      port        = 8080
      target_type = "ip"
      health_check = {
        enabled           = true
        path              = "/health"
        matcher           = "200"
      }
    }
    admin = {
      name_prefix = "admin-"
      protocol    = "HTTP"
      port        = 9000
      target_type = "ip"
      health_check = {
        enabled           = true
        path              = "/admin/health"
        matcher           = "200"
      }
    }
  }

  enable_deletion_protection = true
  tags = module.this.tags
}
```

### 3. Network Load Balancer (NLB) for TCP traffic

```hcl
resource "aws_security_group" "nlb" {
  name_prefix = "nlb-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    description = "MySQL from private subnets"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.this.tags
}

module "nlb" {
  source = "../../modules/alb"

  context = module.this.context
  name    = "database-lb"

  load_balancer_type = "network\"
  internal           = true
  vpc_id             = data.aws_vpc.selected.id
  subnets            = data.aws_subnets.private.ids

  security_groups = [aws_security_group.nlb.id]

  listeners = {
    mysql = {
      port            = 3306
      protocol        = "TCP"
      target_group_key = "mysql"
    }
  }

  target_groups = {
    mysql = {
      name_prefix = "mysql-"
      protocol    = "TCP"
      port        = 3306
      target_type = "instance\"
    }
  }

  idle_timeout = 3600  # NLB TCP: longer idle timeout for database connections

  tags = module.this.tags
}
```

### 4. ALB with WAF integration

```hcl
resource "aws_security_group" "waf_alb" {
  name_prefix = "waf-alb-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.this.tags
}

data "aws_wafv2_web_acl" "owasp" {
  name  = "OWASP-baseline"
  scope = "REGIONAL"
}

module "alb_with_waf" {
  source = "../../modules/alb"

  context = module.this.context
  name    = "production"

  load_balancer_type = "application"
  internal           = false
  vpc_id             = data.aws_vpc.selected.id
  subnets            = data.aws_subnets.public.ids

  security_groups = [aws_security_group.waf_alb.id]

  # Attach WAFv2 Web ACL
  web_acl_arn = data.aws_wafv2_web_acl.owasp.arn

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.aws_acm_certificate.selected.arn
      forward = {
        target_groups = ["app"]
      }
    }
  }

  target_groups = {
    app = {
      name_prefix = "app-"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
    }
  }

  # Stricter desync mitigation for WAF-protected ALB
  desync_mitigation_mode = "strictest"

  enable_deletion_protection = true
  tags = module.this.tags
}
```

### 5. ALB with access logging

```hcl
# Create S3 bucket for logs (with proper permissions)
resource "aws_s3_bucket" "alb_logs" {
  bucket_prefix = "alb-logs-"
  tags          = module.this.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_security_group" "alb_logs" {
  name_prefix = "alb-logs-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.this.tags
}

module "alb_logged" {
  source = "../../modules/alb"

  context = module.this.context
  name    = "logged"

  load_balancer_type = "application"
  internal           = false
  vpc_id             = data.aws_vpc.selected.id
  subnets            = data.aws_subnets.public.ids

  security_groups = [aws_security_group.alb_logs.id]

  # Enable access logging to S3
  access_logs = {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "${terraform.workspace}/alb"
    enabled = true
  }

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.aws_acm_certificate.selected.arn
      forward = {
        target_groups = ["app"]
      }
    }
  }

  target_groups = {
    app = {
      name_prefix = "app-"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
    }
  }

  enable_deletion_protection = true
  tags = module.this.tags
}
```

### 6. ALB with custom security settings

```hcl
resource "aws_security_group" "custom_alb" {
  name_prefix = "custom-alb-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Internal CIDR only
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.this.tags
}

module "alb_custom" {
  source = "../../modules/alb"

  context = module.this.context
  name    = "custom-security"

  load_balancer_type = "application"
  internal           = true
  vpc_id             = data.aws_vpc.selected.id
  subnets            = data.aws_subnets.private.ids

  security_groups = [aws_security_group.custom_alb.id]

  # Longest idle timeout for long-lived connections
  idle_timeout = 3600

  # Preserve original Host header from client
  preserve_host_header = true

  # Remove X-Forwarded-For headers (strict security)
  xff_header_processing_mode = "remove"

  # Disable HTTP/2 for compatibility (if needed)
  enable_http2 = false

  # Disable cross-zone to reduce costs (trade availability for cost)
  enable_cross_zone_load_balancing = false

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.aws_acm_certificate.internal.arn
      forward = {
        target_groups = ["legacy"]
      }
    }
  }

  target_groups = {
    legacy = {
      name_prefix = "legacy-"
      protocol    = "HTTP"
      port        = 8080
      target_type = "instance"
    }
  }

  enable_deletion_protection = false  # Non-prod: allow deletion
  tags = module.this.tags
}
```

## Terraform Validation Rules

This module enforces several validation constraints via `terraform_data` preconditions. These are checked during `terraform plan` and will fail fast if violated:

| Validation | Condition | Resolution |
|---|---|---|
| **Subnet count** | Consumer-controlled | Subnet count is not enforced at module level, allowing flexibility for development/cost-optimized environments (single AZ) or production (multi-AZ). Consumer should specify based on HA requirements. |
| **Internet-facing requires access logs** | `internal == true OR access_logs != null` | Either set `internal = true` for internal LBs, or enable access logging via the `access_logs` variable for internet-facing ALBs/NLBs (compliance requirement). |
| **HTTPS listeners require certificate** | Each HTTPS/TLS listener must have `certificate_arn` | Provide a valid ACM certificate ARN in listener configuration. Example: `certificate_arn = data.aws_acm_certificate.selected.arn` |
| **Security groups required** | `length(var.security_groups) > 0` | Pass at least one pre-created security group ID via `var.security_groups`. |
| **ALB-only settings** | ALB-specific variables only valid for `load_balancer_type = "application"` | Settings like `enable_http2`, `desync_mitigation_mode`, `preserve_host_header`, and `xff_header_processing_mode` are ALB-only. Set to `null` or default values for NLB. |

## Security Group Requirements

**Important:** This module does NOT create security groups. Callers must create and supply security groups via `var.security_groups`.

### Required ingress rules

For **ALB (application load balancer):**

- Port 80 (HTTP): Required if using automatic HTTP→HTTPS redirect
- Port 443 (HTTPS): Required for HTTPS traffic

For **NLB (network load balancer):**

- The port(s) specified in listener definitions (typically 80, 443, or custom TCP ports)

### Required egress rules

- All protocols to target port range (minimum egress to reach registered targets)
- Example: `0.0.0.0/0` on all protocols for maximum flexibility

## Conventions

- **Naming:** Load balancer names are derived from context labels via `module.this.id`
- **Tagging:** All resources (ALB, listeners, target groups) inherit NHS-required tags from context
- **Security groups:** Must be pre-created and passed to this module explicitly
- **Listeners:** Define HTTP, HTTPS, or protocol-specific listeners; HTTP→HTTPS redirect is automatic for ALB (can be disabled)
- **Target groups:** Pass through to the upstream module with full customization

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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | 10.5.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.validation](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

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
| <a name="input_desync_mitigation_mode"></a> [desync\_mitigation\_mode](#input\_desync\_mitigation\_mode) | HTTP request desync mitigation mode. Valid values: 'off', 'defensive', 'strictest', 'monitor'. Only valid for ALB. 'defensive' is the AWS default and recommended for security. See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#desync-mitigation-mode | `string` | `"defensive"` | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | When true, cross-zone load balancing distributes traffic across all registered targets in all enabled AZs. Defaults to true. Incurs additional data transfer costs but provides better availability. | `bool` | `true` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | When true, deletion protection is enabled on the load balancer. Set to false for non-production environments where the load balancer needs to be freely destroyed. | `bool` | `true` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | When true, HTTP/2 is enabled on the ALB. Improves connection efficiency. Only valid for ALB. Defaults to true. | `bool` | `true` | no |
| <a name="input_enable_http_https_redirect"></a> [enable\_http\_https\_redirect](#input\_enable\_http\_https\_redirect) | When true, automatically adds a port-80 HTTP-to-HTTPS (301) redirect listener. Only applies when load\_balancer\_type is 'application'. Set to false if you are defining your own HTTP listener or the ALB is not serving HTTPS traffic. | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | Time in seconds that a connection is allowed to be idle. Valid range: 1–4000. Defaults to 60. Apply to both ALB and NLB. | `number` | `60` | no |
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
| <a name="input_preserve_host_header"></a> [preserve\_host\_header](#input\_preserve\_host\_header) | When true, ALB preserves the original Host header from the client request instead of rewriting it. Only valid for ALB. Defaults to false. | `bool` | `false` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | List of security group IDs to attach to the load balancer.<br/>REQUIRED — callers must pre-create security groups with appropriate ingress/egress rules.<br/>This enforces explicit security group management and prevents accidental exposure.<br/>Example:<br/>  security\_groups = [aws\_security\_group.alb.id] | `list(string)` | n/a | yes |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet IDs to attach to the load balancer. For internet-facing ALBs, use public subnets. | `list(string)` | n/a | yes |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | Map of target group configurations to create. Passed directly to the upstream module.<br/>See https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest<br/>for full schema documentation. | `any` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to this module path. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which the load balancer will be created. | `string` | n/a | yes |
| <a name="input_web_acl_arn"></a> [web\_acl\_arn](#input\_web\_acl\_arn) | ARN of a WAFv2 Web ACL to associate with the load balancer. Only valid for ALB. When null, no WAF association is created. | `string` | `null` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |
| <a name="input_xff_header_processing_mode"></a> [xff\_header\_processing\_mode](#input\_xff\_header\_processing\_mode) | How the ALB handles X-Forwarded-For headers. Valid values: 'append', 'replace', 'remove'. 'append' is AWS default. Only valid for ALB. | `string` | `"append"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the load balancer. Used by WAF to associate a Web ACL. |
| <a name="output_arn_suffix"></a> [arn\_suffix](#output\_arn\_suffix) | ARN suffix of the load balancer. Used with CloudWatch metrics. |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | DNS name of the load balancer. Used by Route53 alias records. |
| <a name="output_id"></a> [id](#output\_id) | ID of the load balancer (same as ARN). |
| <a name="output_listener_rules"></a> [listener\_rules](#output\_listener\_rules) | Map of listener rules created and their attributes. Useful for conditional routing and advanced traffic patterns. |
| <a name="output_listeners"></a> [listeners](#output\_listeners) | Map of listeners created and their attributes. ECS tasks use this for depends\_on. |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the first security group supplied via var.security\_groups (not created by this module; caller-supplied). |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the first security group supplied via var.security\_groups (not created by this module; caller-supplied). |
| <a name="output_target_groups"></a> [target\_groups](#output\_target\_groups) | Map of target groups created and their attributes. ECS tasks reference target\_group ARNs from here. |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Hosted zone ID of the load balancer. Used by Route53 alias records. |
<!-- END_TF_DOCS -->
<!-- markdownlint-enable -->
<!-- vale on -->
