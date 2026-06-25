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
Documentation will be regenerated with `terraform-docs`.
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->