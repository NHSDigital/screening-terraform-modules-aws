# WAF

NHS Screening wrapper around the community
[`cloudposse/waf/aws`](https://registry.terraform.io/modules/cloudposse/waf/aws/latest)
module that consumes shared `context.tf` naming and tagging and leaves WAF rule
composition to the consumer.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| Shared naming and tagging | Uses `context.tf` via `module.this` and forwards that context to the upstream module |
| No embedded platform rules | The module defines no managed rules, custom rules, or rule groups internally |
| Consumer-owned priorities | Consumers pass rule lists directly, avoiding collisions with module-defined priorities |
| External logging resources | Logging destinations are passed in as ARNs instead of being created in this module |
| Standard visibility defaults | `visibility_config` defaults to an enabled CloudWatch metric and sampling configuration |

## Usage

### Minimal WAF with consumer-defined managed rules

```hcl
module "waf" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/waf?ref=<tag>"

  service     = "bcss"
  project     = "portal"
  environment = "prod"
  name        = "frontend"

  managed_rule_group_statement_rules = [
    {
      name            = "aws-common-rules"
      priority        = 10
      override_action = "none"
      statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
      visibility_config = {
        metric_name = "frontend-common-rules"
      }
    }
  ]
}
```

### WAF with external log destination and custom byte-match rule

```hcl
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-frontend"
  retention_in_days = 30
}

module "waf" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/waf?ref=<tag>"

  service     = "bcss"
  project     = "portal"
  environment = "prod"
  name        = "frontend"

  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

  byte_match_statement_rules = [
    {
      name     = "block-admin-path"
      priority = 20
      action   = "block"
      statement = {
        search_string         = "/admin"
        positional_constraint = "STARTS_WITH"
        field_to_match = {
          uri_path = true
        }
        text_transformation = [
          {
            priority = 0
            type     = "NONE"
          }
        ]
      }
      visibility_config = {
        metric_name = "frontend-block-admin-path"
      }
    }
  ]
}
```

### WAF associated to an existing load balancer

```hcl
module "waf" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/waf?ref=<tag>"

  service     = "bcss"
  project     = "portal"
  environment = "prod"
  name        = "frontend"

  association_resource_arns = [module.alb.lb_arn]

  managed_rule_group_statement_rules = [
    {
      name            = "aws-common-rules"
      priority        = 10
      override_action = "none"
      statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
      visibility_config = {
        metric_name = "frontend-common-rules"
      }
    }
  ]
}
```

### Path restriction via a consumer-managed rule group

```hcl
resource "aws_wafv2_ip_set" "webservices_allowlist" {
  name               = "bcss-webservices-allowlist"
  description        = "Source addresses allowed to reach selected BCSS paths"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["10.0.0.0/24"]
}

resource "aws_wafv2_rule_group" "webservices_paths" {
  name     = "bcss-webservices-paths"
  scope    = "REGIONAL"
  capacity = 100

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "bcss-webservices-paths"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "limit-selected-paths"
    priority = 1

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          or_statement {
            statement {
              byte_match_statement {
                search_string = "/bss/dashboardExtracts"

                field_to_match {
                  uri_path {}
                }

                positional_constraint = "CONTAINS"

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }

            statement {
              byte_match_statement {
                search_string = "/bss/rawdatamigration"

                field_to_match {
                  uri_path {}
                }

                positional_constraint = "CONTAINS"

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          }
        }

        statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.webservices_allowlist.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "bcss-webservices-path-guard"
      sampled_requests_enabled   = true
    }
  }
}

module "waf" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/waf?ref=<tag>"

  service     = "bcss"
  project     = "portal"
  environment = "prod"
  name        = "frontend"

  rule_group_reference_statement_rules = [
    {
      name            = "bcss-webservices-paths"
      priority        = 80
      override_action = "none"
      statement = {
        arn = aws_wafv2_rule_group.webservices_paths.arn
      }
      visibility_config = {
        metric_name = "bcss-webservices-paths"
      }
    }
  ]
}
```

## Conventions

* This wrapper does not define any rules internally. Consumers are responsible
  for supplying all WAF rules and ensuring that priorities are unique across all
  rule lists they pass in.
* `visibility_config` defaults to enabled metrics and sampled requests using a
  metric name derived from `module.this.id`.
* Logging destinations must be created outside this module and provided as ARNs
  through `log_destination_configs`.
* The wrapper stays aligned with upstream input names so consumers can move
  between this module and the upstream Cloud Posse module without learning a
  second naming model.

## What this module does NOT do

* Create CloudWatch log groups, Firehose streams, S3 buckets, SNS topics, or
  any other external logging or alerting resources.
* Inject Screening-wide default rules or rule groups.
* Automatically resolve consumer-provided rule priority conflicts.

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
| <a name="module_waf"></a> [waf](#module\_waf) | cloudposse/waf/aws | 1.17.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_association_resource_arns"></a> [association\_resource\_arns](#input\_association\_resource\_arns) | List of resource ARNs to associate with this web ACL, such as an ALB, API Gateway stage, or AppSync resource. | `list(string)` | `[]` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_byte_match_statement_rules"></a> [byte\_match\_statement\_rules](#input\_byte\_match\_statement\_rules) | Byte match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    custom_response = optional(object({<br/>      response_code            = string<br/>      custom_response_body_key = optional(string, null)<br/>      response_header = optional(object({<br/>        name  = string<br/>        value = string<br/>      }), null)<br/>    }), null)<br/>    statement = any<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_custom_response_body"></a> [custom\_response\_body](#input\_custom\_response\_body) | Custom response bodies that can be referenced by block actions. | <pre>map(object({<br/>    content      = string<br/>    content_type = string<br/>  }))</pre> | `{}` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | Default action for requests that do not match any rule. Valid values are allow or block. | `string` | `"allow"` | no |
| <a name="input_default_block_custom_response_body_key"></a> [default\_block\_custom\_response\_body\_key](#input\_default\_block\_custom\_response\_body\_key) | Custom response body key to use when default\_action is block. | `string` | `null` | no |
| <a name="input_default_block_response"></a> [default\_block\_response](#input\_default\_block\_response) | HTTP status code to return when default\_action is block. | `string` | `null` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Friendly description of the WAF web ACL. | `string` | `"Managed by Terraform"` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_geo_allowlist_statement_rules"></a> [geo\_allowlist\_statement\_rules](#input\_geo\_allowlist\_statement\_rules) | Geo allowlist rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    statement  = any<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_geo_match_statement_rules"></a> [geo\_match\_statement\_rules](#input\_geo\_match\_statement\_rules) | Geo match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    custom_response = optional(object({<br/>      response_code            = string<br/>      custom_response_body_key = optional(string, null)<br/>      response_header = optional(object({<br/>        name  = string<br/>        value = string<br/>      }), null)<br/>    }), null)<br/>    statement = any<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_ip_set_reference_statement_rules"></a> [ip\_set\_reference\_statement\_rules](#input\_ip\_set\_reference\_statement\_rules) | IP set reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    custom_response = optional(object({<br/>      response_code            = string<br/>      custom_response_body_key = optional(string, null)<br/>      response_header = optional(object({<br/>        name  = string<br/>        value = string<br/>      }), null)<br/>    }), null)<br/>    statement = any<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_log_destination_configs"></a> [log\_destination\_configs](#input\_log\_destination\_configs) | Destination ARNs for WAF logging. Create log groups, Firehose streams, or S3 buckets outside this module and pass their ARNs here. | `list(string)` | `[]` | no |
| <a name="input_logging_filter"></a> [logging\_filter](#input\_logging\_filter) | Optional WAF logging filter configuration passed directly to the upstream module. | <pre>object({<br/>    default_behavior = string<br/>    filter = list(object({<br/>      behavior    = string<br/>      requirement = string<br/>      condition = list(object({<br/>        action_condition = optional(object({<br/>          action = string<br/>        }), null)<br/>        label_name_condition = optional(object({<br/>          label_name = string<br/>        }), null)<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_managed_rule_group_statement_rules"></a> [managed\_rule\_group\_statement\_rules](#input\_managed\_rule\_group\_statement\_rules) | Managed rule group rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name            = string<br/>    priority        = number<br/>    override_action = optional(string)<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    statement = object({<br/>      name                             = string<br/>      vendor_name                      = string<br/>      scope_down_not_statement_enabled = optional(bool, false)<br/>      scope_down_statement = optional(object({<br/>        byte_match_statement = object({<br/>          positional_constraint = string<br/>          search_string         = string<br/>          field_to_match = object({<br/>            all_query_arguments   = optional(bool)<br/>            body                  = optional(bool)<br/>            method                = optional(bool)<br/>            query_string          = optional(bool)<br/>            single_header         = optional(object({ name = string }))<br/>            single_query_argument = optional(object({ name = string }))<br/>            uri_path              = optional(bool)<br/>          })<br/>          text_transformation = list(object({<br/>            priority = number<br/>            type     = string<br/>          }))<br/>        })<br/>      }), null)<br/>      version = optional(string)<br/>      rule_action_override = optional(map(object({<br/>        action = string<br/>        custom_request_handling = optional(object({<br/>          insert_header = object({<br/>            name  = string<br/>            value = string<br/>          })<br/>        }), null)<br/>        custom_response = optional(object({<br/>          response_code = string<br/>          response_header = optional(object({<br/>            name  = string<br/>            value = string<br/>          }), null)<br/>        }), null)<br/>      })), null)<br/>      managed_rule_group_configs = optional(list(object({<br/>        aws_managed_rules_anti_ddos_rule_set = optional(object({<br/>          sensitivity_to_block = optional(string)<br/>          client_side_action_config = optional(object({<br/>            challenge = object({<br/>              usage_of_action = string<br/>              sensitivity     = optional(string)<br/>              exempt_uri_regular_expression = optional(list(object({<br/>                regex_string = string<br/>              })))<br/>            })<br/>          }))<br/>        }))<br/>        aws_managed_rules_bot_control_rule_set = optional(object({<br/>          inspection_level        = string<br/>          enable_machine_learning = optional(bool, true)<br/>        }), null)<br/>        aws_managed_rules_atp_rule_set = optional(object({<br/>          enable_regex_in_path = optional(bool)<br/>          login_path           = string<br/>          request_inspection = optional(object({<br/>            payload_type = string<br/>            password_field = object({<br/>              identifier = string<br/>            })<br/>            username_field = object({<br/>              identifier = string<br/>            })<br/>          }), null)<br/>          response_inspection = optional(object({<br/>            body_contains = optional(object({<br/>              success_strings = list(string)<br/>              failure_strings = list(string)<br/>            }), null)<br/>            header = optional(object({<br/>              name           = string<br/>              success_values = list(string)<br/>              failure_values = list(string)<br/>            }), null)<br/>            json = optional(object({<br/>              identifier      = string<br/>              success_strings = list(string)<br/>              failure_strings = list(string)<br/>            }), null)<br/>            status_code = optional(object({<br/>              success_codes = list(string)<br/>              failure_codes = list(string)<br/>            }), null)<br/>          }), null)<br/>        }), null)<br/>        aws_managed_rules_acfp_rule_set = optional(object({<br/>          creation_path          = string<br/>          enable_regex_in_path   = optional(bool)<br/>          registration_page_path = string<br/>          request_inspection = optional(object({<br/>            payload_type = string<br/>            password_field = optional(object({<br/>              identifier = string<br/>            }), null)<br/>            username_field = optional(object({<br/>              identifier = string<br/>            }), null)<br/>            email_field = optional(object({<br/>              identifier = string<br/>            }), null)<br/>            address_fields = optional(object({<br/>              identifiers = list(string)<br/>            }), null)<br/>            phone_number_fields = optional(object({<br/>              identifiers = list(string)<br/>            }), null)<br/>          }), null)<br/>          response_inspection = optional(object({<br/>            body_contains = optional(object({<br/>              success_strings = list(string)<br/>              failure_strings = list(string)<br/>            }), null)<br/>            header = optional(object({<br/>              name           = string<br/>              success_values = list(string)<br/>              failure_values = list(string)<br/>            }), null)<br/>            json = optional(object({<br/>              identifier     = string<br/>              success_values = list(string)<br/>              failure_values = list(string)<br/>            }), null)<br/>            status_code = optional(object({<br/>              success_codes = list(string)<br/>              failure_codes = list(string)<br/>            }), null)<br/>          }), null)<br/>        }))<br/>      })), null)<br/>    })<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_nested_statement_rules"></a> [nested\_statement\_rules](#input\_nested\_statement\_rules) | Nested statement rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    custom_response = optional(object({<br/>      response_code            = string<br/>      custom_response_body_key = optional(string, null)<br/>      response_header = optional(object({<br/>        name  = string<br/>        value = string<br/>      }), null)<br/>    }), null)<br/>    statement = object({<br/>      and_statement = object({<br/>        statements = list(object({<br/>          type      = string<br/>          statement = string<br/>        }))<br/>      })<br/>    })<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_rate_based_statement_rules"></a> [rate\_based\_statement\_rules](#input\_rate\_based\_statement\_rules) | Rate-based rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    custom_response = optional(object({<br/>      response_code            = string<br/>      custom_response_body_key = optional(string, null)<br/>      response_header = optional(object({<br/>        name  = string<br/>        value = string<br/>      }), null)<br/>    }), null)<br/>    statement = object({<br/>      limit                 = number<br/>      aggregate_key_type    = string<br/>      evaluation_window_sec = optional(number)<br/>      forwarded_ip_config = optional(object({<br/>        fallback_behavior = string<br/>        header_name       = string<br/>      }), null)<br/>      custom_key = optional(list(object({<br/>        ip = optional(object({}), null)<br/>        header = optional(object({<br/>          name = string<br/>          text_transformation = list(object({<br/>            priority = number<br/>            type     = string<br/>          }))<br/>        }), null)<br/>      })), null)<br/>      scope_down_statement = optional(object({<br/>        byte_match_statement = object({<br/>          positional_constraint = string<br/>          search_string         = string<br/>          field_to_match = object({<br/>            all_query_arguments   = optional(bool)<br/>            body                  = optional(bool)<br/>            method                = optional(bool)<br/>            query_string          = optional(bool)<br/>            single_header         = optional(object({ name = string }))<br/>            single_query_argument = optional(object({ name = string }))<br/>            uri_path              = optional(bool)<br/>          })<br/>          text_transformation = list(object({<br/>            priority = number<br/>            type     = string<br/>          }))<br/>        })<br/>      }), null)<br/>    })<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_redacted_fields"></a> [redacted\_fields](#input\_redacted\_fields) | Optional log redaction settings passed directly to the upstream module. | <pre>map(object({<br/>    method        = optional(bool, false)<br/>    uri_path      = optional(bool, false)<br/>    query_string  = optional(bool, false)<br/>    single_header = optional(list(string), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_regex_match_statement_rules"></a> [regex\_match\_statement\_rules](#input\_regex\_match\_statement\_rules) | Regex match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    statement  = any<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_regex_pattern_set_reference_statement_rules"></a> [regex\_pattern\_set\_reference\_statement\_rules](#input\_regex\_pattern\_set\_reference\_statement\_rules) | Regex pattern set reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    statement  = any<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_rule_group_reference_statement_rules"></a> [rule\_group\_reference\_statement\_rules](#input\_rule\_group\_reference\_statement\_rules) | Rule group reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name            = string<br/>    priority        = number<br/>    override_action = optional(string)<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    statement = object({<br/>      arn = string<br/>      rule_action_override = optional(map(object({<br/>        action = string<br/>        custom_request_handling = optional(object({<br/>          insert_header = object({<br/>            name  = string<br/>            value = string<br/>          })<br/>        }), null)<br/>        custom_response = optional(object({<br/>          response_code = string<br/>          response_header = optional(object({<br/>            name  = string<br/>            value = string<br/>          }), null)<br/>        }), null)<br/>      })), null)<br/>    })<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | Whether the web ACL is regional or for CloudFront. | `string` | `"REGIONAL"` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_size_constraint_statement_rules"></a> [size\_constraint\_statement\_rules](#input\_size\_constraint\_statement\_rules) | Size constraint rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    custom_response = optional(object({<br/>      response_code            = string<br/>      custom_response_body_key = optional(string, null)<br/>      response_header = optional(object({<br/>        name  = string<br/>        value = string<br/>      }), null)<br/>    }), null)<br/>    statement = any<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_sqli_match_statement_rules"></a> [sqli\_match\_statement\_rules](#input\_sqli\_match\_statement\_rules) | SQL injection match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    statement  = any<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_token_domains"></a> [token\_domains](#input\_token\_domains) | Optional list of token domains accepted by AWS WAF for cross-domain token usage. | `list(string)` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_visibility_config"></a> [visibility\_config](#input\_visibility\_config) | Visibility configuration for the web ACL. Leave null to use the module default metric name and sampling settings. | <pre>object({<br/>    cloudwatch_metrics_enabled = bool<br/>    metric_name                = string<br/>    sampled_requests_enabled   = bool<br/>  })</pre> | `null` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |
| <a name="input_xss_match_statement_rules"></a> [xss\_match\_statement\_rules](#input\_xss\_match\_statement\_rules) | Cross-site scripting match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    captcha_config = optional(object({<br/>      immunity_time_property = object({<br/>        immunity_time = number<br/>      })<br/>    }), null)<br/>    rule_label = optional(list(string), null)<br/>    statement  = any<br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool)<br/>      metric_name                = string<br/>      sampled_requests_enabled   = optional(bool)<br/>    }), null)<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_logging_config_id"></a> [logging\_config\_id](#output\_logging\_config\_id) | ARN of the WAF logging configuration when logging is enabled. |
| <a name="output_web_acl_arn"></a> [web\_acl\_arn](#output\_web\_acl\_arn) | ARN of the WAF web ACL. |
| <a name="output_web_acl_capacity"></a> [web\_acl\_capacity](#output\_web\_acl\_capacity) | Current WAF capacity usage in WCUs. |
| <a name="output_web_acl_id"></a> [web\_acl\_id](#output\_web\_acl\_id) | ID of the WAF web ACL. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
