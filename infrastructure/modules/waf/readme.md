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

### path restriction via a consumer-managed rule group

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
* Automatically deconflict consumer-provided rule priorities.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.13 |
| aws | >= 6.42 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| this | ../tags | n/a |
| waf | cloudposse/waf/aws | 1.17.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| association_resource_arns | List of resource ARNs to associate with this web ACL, such as an ALB, API Gateway stage, or AppSync resource. | list(string) | `[]` | no |
| byte_match_statement_rules | Byte match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| custom_response_body | Custom response bodies that can be referenced by block actions. | map(object) | `{}` | no |
| default_action | Default action for requests that do not match any rule. Valid values are allow or block. | string | `"allow"` | no |
| default_block_custom_response_body_key | Custom response body key to use when default_action is block. | string | `null` | no |
| default_block_response | HTTP status code to return when default_action is block. | string | `null` | no |
| description | Friendly description of the WAF web ACL. | string | `"Managed by Terraform"` | no |
| geo_allowlist_statement_rules | Geo allowlist rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| geo_match_statement_rules | Geo match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| ip_set_reference_statement_rules | IP set reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| log_destination_configs | Destination ARNs for WAF logging. Create log groups, Firehose streams, or S3 buckets outside this module and pass their ARNs here. | list(string) | `[]` | no |
| logging_filter | Optional WAF logging filter configuration passed directly to the upstream module. | object | `null` | no |
| managed_rule_group_statement_rules | Managed rule group rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| nested_statement_rules | Nested statement rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| rate_based_statement_rules | Rate-based rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| redacted_fields | Optional log redaction settings passed directly to the upstream module. | map(object) | `{}` | no |
| regex_match_statement_rules | Regex match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| regex_pattern_set_reference_statement_rules | Regex pattern set reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| rule_group_reference_statement_rules | Rule group reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| scope | Whether the web ACL is regional or for CloudFront. | string | `"REGIONAL"` | no |
| size_constraint_statement_rules | Size constraint rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| sqli_match_statement_rules | SQL injection match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |
| token_domains | Optional list of token domains accepted by AWS WAF for cross-domain token usage. | list(string) | `null` | no |
| visibility_config | Visibility configuration for the web ACL. Leave null to use the module default metric name and sampling settings. | object | `null` | no |
| xss_match_statement_rules | Cross-site scripting match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists. | list(object) | `[]` | no |

Standard naming and tagging inputs are also provided via `context.tf`, including `service`, `project`, `environment`, `name`, `stack`, `workspace`, `tags`, and the full shared context object.

## Outputs

| Name | Description |
| ---- | ----------- |
| logging_config_id | ARN of the WAF logging configuration when logging is enabled. |
| web_acl_arn | ARN of the WAF web ACL. |
| web_acl_capacity | Current WAF capacity usage in WCUs. |
| web_acl_id | ID of the WAF web ACL. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->