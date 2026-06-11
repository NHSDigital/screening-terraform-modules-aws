
locals {
  context_id = trimspace(module.this.id) != "" ? module.this.id : null

  derived_name_prefix = coalesce(var.name_prefix, local.context_id, "waf")
  derived_waf_name    = coalesce(var.waf_name, local.derived_name_prefix)
  derived_log_group_name = coalesce(
    var.waf_log_group_name,
    "aws-waf-logs-${local.derived_name_prefix}"
  )

  enable_legacy_bcss_mode = var.enable_legacy_bcss_mode != null ? var.enable_legacy_bcss_mode : anytrue([
    var.name_prefix != null,
    var.waf_name != null,
    var.waf_log_group_name != null,
    var.exclude_ip_set_name != null,
    var.web_services_ip_set_name != null
  ])

  enable_legacy_geo_rule = var.enable_legacy_geo_rule != null ? var.enable_legacy_geo_rule : local.enable_legacy_bcss_mode
  create_waf_log_group = var.create_waf_log_group != null ? var.create_waf_log_group : local.enable_legacy_bcss_mode
  enable_central_logging_subscription = var.enable_central_logging_subscription != null ? var.enable_central_logging_subscription : local.enable_legacy_bcss_mode
  enable_splunk_logging_subscription  = var.enable_splunk_logging_subscription != null ? var.enable_splunk_logging_subscription : local.enable_legacy_bcss_mode
  enable_shield_ddos_alarming         = var.enable_shield_ddos_alarming != null ? var.enable_shield_ddos_alarming : local.enable_legacy_bcss_mode

  waf_ips_secret_name = coalesce(
    var.waf_ips_secret_name,
    var.name_prefix != null ? "${var.name_prefix}-waf-ip-set" : null
  )
  waf_bsis_ip_range_secret_name = coalesce(
    var.waf_bsis_ip_range_secret_name,
    var.name_prefix != null ? "${var.name_prefix}-waf-bsis-ip" : null
  )
  cloudwatch_cross_account_secret_name = coalesce(
    var.cloudwatch_cross_account_secret_name,
    var.name_prefix != null ? "${var.name_prefix}-cloudwatch-cross-account-logging" : null
  )
  alert_sns_topic_name = coalesce(var.alert_sns_topic_name, var.name_prefix)

  default_visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.derived_name_prefix}-waf-acl-metric"
    sampled_requests_enabled   = true
  }
  visibility_config = var.visibility_config != null ? var.visibility_config : local.default_visibility_config

  default_managed_rule_group_statement_rules = [
    {
      name            = "${local.derived_name_prefix}-aws-common-rule-set"
      priority        = 10
      override_action = "count"
      statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
      visibility_config = {
        metric_name = "${local.derived_name_prefix}-waf-aws-common-rule-set-metric"
      }
    },
    {
      name            = "${local.derived_name_prefix}-aws-bad-inputs-rule-set"
      priority        = 20
      override_action = "count"
      statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
      visibility_config = {
        metric_name = "${local.derived_name_prefix}-waf-aws-bad-inputs-rule-set-metric"
      }
    },
    {
      name            = "${local.derived_name_prefix}-aws-ip-reputation-list"
      priority        = 30
      override_action = "count"
      statement = {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
      visibility_config = {
        metric_name = "${local.derived_name_prefix}-waf-aws-ip-reputation-list-metric"
      }
    },
    {
      name            = "${local.derived_name_prefix}-aws-sql-injection-rules"
      priority        = 40
      override_action = "count"
      statement = {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
      visibility_config = {
        metric_name = "${local.derived_name_prefix}-waf-aws-sql-injection-rules-metric"
      }
    },
    {
      name            = "${local.derived_name_prefix}-waf-aws-anonymous-ip-list-set"
      priority        = 50
      override_action = "none"
      statement = {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
      visibility_config = {
        metric_name = "${local.derived_name_prefix}-waf-aws-anonymous-ip-list-set-metric"
      }
    },
    {
      name            = "${local.derived_name_prefix}-waf-aws-linux-rule-set"
      priority        = 60
      override_action = "none"
      statement = {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
      visibility_config = {
        metric_name = "${local.derived_name_prefix}-waf-aws-linux-rule-set-metric"
      }
    }
  ]

  legacy_geo_match_statement_rules = local.enable_legacy_geo_rule ? [
    {
      name     = "${local.derived_name_prefix}-waf-non-GB-geo-match"
      priority = var.legacy_geo_rule_priority
      action   = "count"
      statement = {
        country_codes = ["GB"]
      }
      visibility_config = {
        metric_name = "${local.derived_name_prefix}-waf-non-GB-geo-match-metric"
      }
    }
  ] : []

  managed_rule_group_statement_rules = length(var.managed_rule_group_statement_rules) > 0 ? var.managed_rule_group_statement_rules : local.default_managed_rule_group_statement_rules
}

data "aws_secretsmanager_secret_version" "waf_ips" {
  count     = local.enable_legacy_bcss_mode && var.exclude_ip_set_addresses == null && local.waf_ips_secret_name != null ? 1 : 0
  secret_id = local.waf_ips_secret_name
}

data "aws_secretsmanager_secret_version" "waf_bsis_ip_range" {
  count     = local.enable_legacy_bcss_mode && var.webservices_ip_set_addresses == null && local.waf_bsis_ip_range_secret_name != null ? 1 : 0
  secret_id = local.waf_bsis_ip_range_secret_name
}

data "aws_secretsmanager_secret" "cloudwatch_cross_accounts" {
  count = local.create_waf_log_group && local.enable_central_logging_subscription && local.cloudwatch_cross_account_secret_name != null ? 1 : 0
  name  = local.cloudwatch_cross_account_secret_name
}

data "aws_secretsmanager_secret_version" "cloudwatch_cross_accounts" {
  count     = length(data.aws_secretsmanager_secret.cloudwatch_cross_accounts) > 0 ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.cloudwatch_cross_accounts[0].id
}

data "aws_sns_topic" "alert" {
  count = local.enable_shield_ddos_alarming && lower(coalesce(module.this.environment, var.environment, "")) == "prod" && local.alert_sns_topic_name != null ? 1 : 0
  name  = local.alert_sns_topic_name
}

locals {
  exclude_ip_addresses = var.exclude_ip_set_addresses != null ? var.exclude_ip_set_addresses : (
    length(data.aws_secretsmanager_secret_version.waf_ips) > 0 ? try(
      jsondecode(data.aws_secretsmanager_secret_version.waf_ips[0].secret_string)[var.waf_ips_secret_key],
      []
    ) : []
  )

  webservices_ip_addresses = var.webservices_ip_set_addresses != null ? var.webservices_ip_set_addresses : (
    length(data.aws_secretsmanager_secret_version.waf_bsis_ip_range) > 0 ? try(
      jsondecode(data.aws_secretsmanager_secret_version.waf_bsis_ip_range[0].secret_string)[var.waf_bsis_ip_range_secret_key],
      []
    ) : []
  )

  cross_account_id = length(data.aws_secretsmanager_secret_version.cloudwatch_cross_accounts) > 0 ? try(
    jsondecode(data.aws_secretsmanager_secret_version.cloudwatch_cross_accounts[0].secret_string)[var.cloudwatch_cross_account_secret_key],
    null
  ) : null

  create_legacy_exclude_ip_set = local.enable_legacy_bcss_mode && var.exclude_ip_set_name != null && length(local.exclude_ip_addresses) > 0
  create_legacy_webservices_ip_set = local.enable_legacy_bcss_mode && var.web_services_ip_set_name != null && length(local.webservices_ip_addresses) > 0
  create_legacy_webservices_rule_group = local.create_legacy_webservices_ip_set && length(var.webservices_protected_paths) > 0

  combined_geo_match_statement_rules = concat(var.geo_match_statement_rules, local.legacy_geo_match_statement_rules)
  combined_rule_group_reference_statement_rules = concat(
    var.rule_group_reference_statement_rules,
    local.create_legacy_webservices_rule_group ? [
      {
        name            = "${local.derived_name_prefix}-legacy-webservices-rule-group"
        priority        = var.legacy_webservices_rule_priority
        override_action = "none"
        statement = {
          arn = aws_wafv2_rule_group.legacy_webservices[0].arn
        }
        visibility_config = {
          metric_name = "${local.derived_name_prefix}-legacy-webservices-rule-group"
        }
      }
    ] : []
  )

  combined_log_destination_configs = distinct(concat(
    var.log_destination_configs,
    local.create_waf_log_group ? [aws_cloudwatch_log_group.waf_logs[0].arn] : []
  ))

  cloudposse_context = merge(module.this.context, {
    name      = local.derived_waf_name
    namespace = null
    stage     = null
    tenant    = null
    tags      = module.this.tags
  })
}

resource "aws_wafv2_ip_set" "legacy_exclude" {
  count = local.create_legacy_exclude_ip_set ? 1 : 0

  name               = var.exclude_ip_set_name
  description        = "Legacy BCSS excluded IP addresses"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = local.exclude_ip_addresses
  tags               = module.this.tags
}

resource "aws_wafv2_ip_set" "legacy_webservices" {
  count = local.create_legacy_webservices_ip_set ? 1 : 0

  name               = var.web_services_ip_set_name
  description        = "Legacy BCSS webservices allowlist IP addresses"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = local.webservices_ip_addresses
  tags               = module.this.tags
}

resource "aws_wafv2_rule_group" "legacy_webservices" {
  count = local.create_legacy_webservices_rule_group ? 1 : 0

  name        = "${local.derived_name_prefix}-legacy-webservices"
  description = "Legacy BCSS rule that restricts selected paths to the webservices allowlist"
  scope       = var.scope
  capacity    = var.legacy_webservices_rule_capacity
  tags        = module.this.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.derived_name_prefix}-legacy-webservices"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "webservices-allowlist"
    priority = 1

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          or_statement {
            dynamic "statement" {
              for_each = toset(var.webservices_protected_paths)

              content {
                byte_match_statement {
                  search_string = statement.value

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
        }

        statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.legacy_webservices[0].arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.derived_name_prefix}-legacy-webservices-rule"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  count = local.create_waf_log_group ? 1 : 0

  name              = local.derived_log_group_name
  retention_in_days = var.waf_log_retention_in_days
  tags              = module.this.tags
}

module "waf" {
  source  = "cloudposse/waf/aws"
  version = "1.17.0"

  scope                       = var.scope
  description                 = var.description
  default_action              = var.default_action
  visibility_config           = local.visibility_config
  association_resource_arns   = var.association_resource_arns
  log_destination_configs     = local.combined_log_destination_configs
  token_domains               = var.token_domains
  managed_rule_group_statement_rules = local.managed_rule_group_statement_rules
  geo_match_statement_rules          = local.combined_geo_match_statement_rules
  ip_set_reference_statement_rules   = var.ip_set_reference_statement_rules
  rate_based_statement_rules         = var.rate_based_statement_rules
  rule_group_reference_statement_rules = local.combined_rule_group_reference_statement_rules

  context = local.cloudposse_context
}

data "aws_iam_policy_document" "central_logs_assume_role" {
  count = local.create_waf_log_group && local.enable_central_logging_subscription && local.cross_account_id != null && var.aws_account_id != null ? 1 : 0

  statement {
    sid     = "centralLogsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cw_to_subscription_filter_role" {
  count = length(data.aws_iam_policy_document.central_logs_assume_role) > 0 ? 1 : 0

  name               = "${local.derived_name_prefix}_CWLtoSubscriptionFilterRole"
  assume_role_policy = data.aws_iam_policy_document.central_logs_assume_role[0].json
  tags               = module.this.tags
}

data "aws_iam_policy_document" "central_cw_subscription_doc_policy" {
  count = length(aws_iam_role.cw_to_subscription_filter_role) > 0 ? 1 : 0

  statement {
    actions = ["logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:${local.derived_log_group_name}:*"
    ]
  }
}

resource "aws_iam_policy" "central_cw_subscription_iam_policy" {
  count = length(data.aws_iam_policy_document.central_cw_subscription_doc_policy) > 0 ? 1 : 0

  name   = "${local.derived_name_prefix}_central_cw_subscription"
  policy = data.aws_iam_policy_document.central_cw_subscription_doc_policy[0].json
  tags   = module.this.tags
}

resource "aws_iam_role_policy_attachment" "central_logging_att" {
  count = length(aws_iam_policy.central_cw_subscription_iam_policy) > 0 ? 1 : 0

  policy_arn = aws_iam_policy.central_cw_subscription_iam_policy[0].arn
  role       = aws_iam_role.cw_to_subscription_filter_role[0].id
}

resource "time_sleep" "wait_30_seconds" {
  count = length(aws_iam_role.cw_to_subscription_filter_role) > 0 ? 1 : 0

  depends_on      = [aws_iam_role.cw_to_subscription_filter_role]
  create_duration = "30s"
}

resource "aws_cloudwatch_log_subscription_filter" "central_logging" {
  count = local.create_waf_log_group && local.enable_central_logging_subscription && local.cross_account_id != null && length(aws_iam_role.cw_to_subscription_filter_role) > 0 ? 1 : 0

  name            = "${local.derived_name_prefix}_central_logging"
  role_arn        = aws_iam_role.cw_to_subscription_filter_role[0].arn
  log_group_name  = aws_cloudwatch_log_group.waf_logs[0].name
  filter_pattern  = ""
  destination_arn = "arn:aws:logs:${var.aws_region}:${local.cross_account_id}:destination:waf_log_destination"
  distribution    = "ByLogStream"

  depends_on = [
    aws_cloudwatch_log_group.waf_logs,
    time_sleep.wait_30_seconds
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "splunk_subscr_filter" {
  count = local.create_waf_log_group && local.enable_splunk_logging_subscription && var.aws_account_id != null ? 1 : 0

  name            = "${local.derived_name_prefix}_splunk_subscr_filter"
  role_arn        = "arn:aws:iam::${var.aws_account_id}:role/${local.derived_name_prefix}-CloudWatchToFirehoseRole"
  log_group_name  = aws_cloudwatch_log_group.waf_logs[0].name
  filter_pattern  = ""
  destination_arn = "arn:aws:firehose:${var.aws_region}:${var.aws_account_id}:deliverystream/${local.derived_name_prefix}-cw-logs-firehose"
  distribution    = "ByLogStream"

  depends_on = [aws_cloudwatch_log_group.waf_logs]
}

resource "aws_iam_role" "eventbridge_role" {
  count = local.enable_shield_ddos_alarming && lower(coalesce(module.this.environment, var.environment, "")) == "prod" && local.cross_account_id != null && var.aws_account_id != null ? 1 : 0

  name = "${local.derived_name_prefix}-eventbridge-trust-role"
  tags = module.this.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TrustEventBridgeService"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.aws_account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_put_events" {
  count = length(aws_iam_role.eventbridge_role) > 0 ? 1 : 0

  name = "${local.derived_name_prefix}-eventbridge-put-events"
  role = aws_iam_role.eventbridge_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ActionsForResource"
        Effect = "Allow"
        Action = ["events:PutEvents"]
        Resource = [
          "arn:aws:events:${var.shield_event_bus_region}:${local.cross_account_id}:event-bus/shield-eventbus"
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "shield_ddos_alarm" {
  count = length(data.aws_sns_topic.alert) > 0 ? 1 : 0

  alarm_name          = "${local.derived_name_prefix}_shield_ddos_WAF"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 20
  datapoints_to_alarm = 1
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    ResourceArn = module.waf.arn
  }

  alarm_actions             = [data.aws_sns_topic.alert[0].arn]
  ok_actions                = [data.aws_sns_topic.alert[0].arn]
  insufficient_data_actions = []
  alarm_description         = "Alarm triggers when Shield Advanced detects a DDoS attack on production WAF"
  tags                      = module.this.tags
}

resource "aws_cloudwatch_event_rule" "shield_ddos_rule" {
  count = length(aws_cloudwatch_metric_alarm.shield_ddos_alarm) > 0 ? 1 : 0

  name        = "${local.derived_name_prefix}_shield_ddos_rules"
  description = "Forward DDoS alarm state change events to cross-account EventBridge bus"
  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    resources     = [aws_cloudwatch_metric_alarm.shield_ddos_alarm[0].arn]
  })
  tags = module.this.tags
}

resource "aws_cloudwatch_event_target" "shield_ddos_target" {
  count = length(aws_cloudwatch_event_rule.shield_ddos_rule) > 0 ? 1 : 0

  rule      = aws_cloudwatch_event_rule.shield_ddos_rule[0].name
  target_id = "${local.derived_name_prefix}-shield-ddos-target"
  arn       = "arn:aws:events:${var.shield_event_bus_region}:${local.cross_account_id}:event-bus/shield-eventbus"
  role_arn  = aws_iam_role.eventbridge_role[0].arn
}
