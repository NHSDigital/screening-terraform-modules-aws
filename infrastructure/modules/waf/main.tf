
# tflint-ignore: terraform_naming_convention
data "aws_secretsmanager_secret_version" "waf_ips" {
  count     = local.enable_legacy_bcss_mode && var.exclude_ip_set_addresses == null && local.waf_ips_secret_name != null ? 1 : 0
  secret_id = local.waf_ips_secret_name
}
# tflint-ignore: terraform_naming_convention
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
  ip_list  = jsondecode(data.aws_secretsmanager_secret_version.waf_ips.secret_string).ips
  bsis_ips = jsondecode(data.aws_secretsmanager_secret_version.waf_bsis_ip_range.secret_string).bsis_ip
}

#######################
#  IP Sets ToDo: Check if the is relevant to our environment
#######################
#### Please note this resource creation might fail on the first run with error stating resource already exists (eventhough Terraform logs shows it is destroyrd)
# whenever there is change ticket raised to investigate this https://nhsd-jira.digital.nhs.uk/browse/SCM-726
#####
# tflint-ignore: terraform_naming_convention
resource "aws_wafv2_ip_set" "bs-select-exclude-ip-set" {
  name               = var.exclude_ip_set_name
  description        = "Legacy BCSS excluded IP addresses"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = local.exclude_ip_addresses
  tags               = module.this.tags
}

#########For web Services add/remove on tfvars#########
# tflint-ignore: terraform_naming_convention
resource "aws_wafv2_ip_set" "bs-select-webservices-ip-set" {
  name               = var.web_services_ip_set_name
  description        = "Legacy BCSS webservices allowlist IP addresses"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = local.bsis_ips
}

######################
#  WAF
######################


# tflint-ignore: terraform_naming_convention
resource "aws_wafv2_web_acl" "bss-waf-acl" {
  name  = var.waf_name
  scope = "REGIONAL"
  #checkov:skip=CKV_AWS_192:Even after adding required code to manage log4j still checkov failing ,New ticket- https://nhsd-jira.digital.nhs.uk/browse/SCM-695 raised to check this

  default_action {
    allow {}
  }

  # Primary Web ACL metric
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
  # Note CW log group name should begin aws-waf-logs
  name              = var.waf_log_group_name
  retention_in_days = 365
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_acl_lc" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.bss-waf-acl.arn
}
# Create a CloudWatch Log Group with KMS Encryption

##################################
####### Forward logs to CSOC #####
##################################

# Create IAM role necessary for cross-account log subscriptions
resource "aws_iam_role" "cw_to_subscription_filter_role" {
  name               = "${var.name_prefix}_CWLtoSubscriptionFilterRole"
  assume_role_policy = data.aws_iam_policy_document.central_logs_assume_role.json
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
  policy_arn = aws_iam_policy.central_cw_subscription_iam_policy.arn
  role       = aws_iam_role.cw_to_subscription_filter_role.id
}

# tflint-ignore: terraform_naming_convention
data "aws_secretsmanager_secret" "cloudwatch-cross-accounts" {
  name = "${var.name_prefix}-cloudwatch-cross-account-logging"
}

# tflint-ignore: terraform_naming_convention
data "aws_secretsmanager_secret_version" "cloudwatch-cross-accounts" {
  secret_id = data.aws_secretsmanager_secret.cloudwatch-cross-accounts.id
}

locals {
  cross_account_id = jsondecode(data.aws_secretsmanager_secret_version.cloudwatch-cross-accounts.secret_string)["central-logging"]
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
