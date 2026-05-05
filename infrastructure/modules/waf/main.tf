
data "aws_secretsmanager_secret_version" "waf_ips" {
  secret_id = "${var.name_prefix}-waf-ip-set"
}
data "aws_secretsmanager_secret_version" "waf_bsis_ip_range" {
  secret_id = "${var.name_prefix}-waf-bsis-ip"
}

data "aws_sns_topic" "alert" {
  name = var.name_prefix
}

locals {
  ip_list = jsondecode(data.aws_secretsmanager_secret_version.waf_ips.secret_string).ips
  bsis_ips = jsondecode(data.aws_secretsmanager_secret_version.waf_bsis_ip_range.secret_string).bsis_ip
}

#######################
#  IP Sets ToDo: Check if the is relevant to our environment
#######################
#### Please note this resource creation might fail on the first run with error stating resource already exists (eventhough Terraform logs shows it is destroyrd)
# whenever there is change ticket raised to investigate this https://nhsd-jira.digital.nhs.uk/browse/SCM-726
#####
resource "aws_wafv2_ip_set" "bs-select-exclude-ip-set" {
  name               = var.exclude_ip_set_name
  description        = "This set of IPs are excluded from Anonymous and linux rule"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.ip_list
}

#########For web Services add/remove on tfvars#########
resource "aws_wafv2_ip_set" "bs-select-webservices-ip-set" {
  name               = var.web_services_ip_set_name
  description        = "This set of IPs are excluded from Anonymous and linux rule"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.bsis_ips
}

######################
#  WAF
######################


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
    metric_name                = "${var.name_prefix}-waf-acl-metric"
    sampled_requests_enabled   = true
  }

  # Custom rule for paths and IP set exclusion
  rule {
    name     = "bss-webservices-rule"
    priority = 80

    action {
      block {}
    }
    # web service rules
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
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
                positional_constraint = "CONTAINS"
              }
            }
            # Statements not currently in live, ticket SCM-1826 created to investigate
            # statement {
            #   byte_match_statement {
            #     search_string = "/bss/screeningbatchresults"
            #     field_to_match {
            #       uri_path {}
            #     }
            #     text_transformation {
            #       priority = 0
            #       type     = "NONE"
            #     }
            #     positional_constraint = "CONTAINS"
            #   }
            # }
            # statement {
            #   byte_match_statement {
            #     search_string = "/bss/nonbatchreferrals"
            #     field_to_match {
            #       uri_path {}
            #     }
            #     text_transformation {
            #       priority = 0
            #       type     = "NONE"
            #     }
            #     positional_constraint = "CONTAINS"
            #   }
            # }
            statement {
              byte_match_statement {
                search_string = "/bss/rawdatamigration"
                field_to_match {
                  uri_path {}
                }
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
                positional_constraint = "CONTAINS"
              }
            }
          }
        }

        # Not statement to block requests that are not from the allowed IP set
        statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.bs-select-webservices-ip-set.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "bss-webservices-rule"
      sampled_requests_enabled   = true
    }
  }

  # Base rules for all service teams
  rule {
    name     = "${var.name_prefix}-aws-common-rule-set"
    priority = 10

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-waf-aws-common-rule-set-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${var.name_prefix}-aws-bad-inputs-rule-set"
    priority = 20

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-waf-aws-bad-inputs-rule-set-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${var.name_prefix}-aws-ip-reputation-list"
    priority = 30

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-waf-aws-ip-reputation-list-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${var.name_prefix}-aws-sql-injection-rules"
    priority = 40

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-waf-aws-sql-injection-rules-metric"
      sampled_requests_enabled   = true
    }
  }

  # Service-team specfic rules
  rule {
    name     = "${var.name_prefix}-waf-non-GB-geo-match"
    priority = 100
    action {
      count {}
    }
    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["GB"]
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-waf-non-GB-geo-match-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${var.name_prefix}-waf-aws-anonymous-ip-list-set"
    priority = 50

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
        scope_down_statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.bs-select-exclude-ip-set.arn
              }
            }

          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-waf-aws-anonymous-ip-list-set-metric"
      sampled_requests_enabled   = true
    }
  }


  rule {
    name     = "${var.name_prefix}-waf-aws-linux-rule-set"
    priority = 60

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"

        scope_down_statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.bs-select-exclude-ip-set.arn
              }
            }

          }
        }
      }
    }


    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-waf-aws-linux-rule-set-metric"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 70

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-waf-known-bad-inputs-rules"
      sampled_requests_enabled   = true
    }

  }

}

resource "aws_cloudwatch_log_group" "waf_logs" {
  // Note CW log group name should begin aws-waf-logs
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



# Permissions policy to define actions cloudwatch logs can perform
resource "aws_iam_policy" "central_cw_subscription_iam_policy" {
  name   = "${var.name_prefix}_central_cw_subscription"
  policy = data.aws_iam_policy_document.central_cw_subscription_doc_policy.json
}

data "aws_iam_policy_document" "central_cw_subscription_doc_policy" {
  statement {
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:aws-waf-logs-${var.name_prefix}:*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "central_logging_att" {
  policy_arn = aws_iam_policy.central_cw_subscription_iam_policy.arn
  role       = aws_iam_role.cw_to_subscription_filter_role.id
}

data "aws_secretsmanager_secret" "cloudwatch-cross-accounts" {
  name = "${var.name_prefix}-cloudwatch-cross-account-logging"
}

data "aws_secretsmanager_secret_version" "cloudwatch-cross-accounts" {
  secret_id = data.aws_secretsmanager_secret.cloudwatch-cross-accounts.id
}

locals {
  cross_account_id = jsondecode(data.aws_secretsmanager_secret_version.cloudwatch-cross-accounts.secret_string)["central-logging"]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on      = [aws_iam_role.cw_to_subscription_filter_role]
  create_duration = "30s"
}
# The subscription filter to send to the central logging
resource "aws_cloudwatch_log_subscription_filter" "central_logging" {
  name            = "${var.name_prefix}_central_logging"
  role_arn        = aws_iam_role.cw_to_subscription_filter_role.arn
  log_group_name  = var.waf_log_group_name
  filter_pattern  = ""
  destination_arn = "arn:aws:logs:${var.aws_region}:${local.cross_account_id}:destination:waf_log_destination"
  distribution    = "ByLogStream"

  depends_on = [
    aws_iam_role.cw_to_subscription_filter_role,
    aws_cloudwatch_log_group.waf_logs,
    time_sleep.wait_30_seconds
  ]
}

# Send to splunk as well for our own logging/troubleshooting
resource "aws_cloudwatch_log_subscription_filter" "splunk_subscr_filter" {
  name            = "${var.name_prefix}_splunk_subscr_filter"
  role_arn        = "arn:aws:iam::${var.aws_account_id}:role/${var.name_prefix}-CloudWatchToFirehoseRole"
  log_group_name  = var.waf_log_group_name
  filter_pattern  = ""
  destination_arn = "arn:aws:firehose:${var.aws_region}:${var.aws_account_id}:deliverystream/${var.name_prefix}-cw-logs-firehose"
  distribution    = "ByLogStream"

  depends_on = [
    aws_cloudwatch_log_group.waf_logs
  ]
}

##############################
# DDoS Alarm logs forwarding to CSOC
##############################
resource "aws_iam_role" "eventbridge_role" {
  count = contains(["prod"], var.environment) ? 1 : 0
  name  = "${var.name_prefix}-eventbridge-trust-role"

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
            "aws:SourceAccount" = "${var.aws_account_id}"
          }
        }
      }
    ]
  })
}
resource "aws_iam_role_policy" "eventbridge_put_events" {
  count = contains(["prod"], var.environment) ? 1 : 0

  name = "${var.name_prefix}-eventbridge-put-events"
  role = aws_iam_role.eventbridge_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ActionsForResource"
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = [
          "arn:aws:events:eu-west-2:${local.cross_account_id}:event-bus/shield-eventbus"
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "shield_ddos_alarm" {
  count               = contains(["prod"], var.environment) ? 1 : 0
  alarm_name          = "${var.name_prefix}_shield_ddos_WAF"
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
    ResourceArn = aws_wafv2_web_acl.bss-waf-acl.arn
  }

  alarm_actions             = [data.aws_sns_topic.alert.arn]
  ok_actions                = [data.aws_sns_topic.alert.arn]
  insufficient_data_actions = []

  alarm_description = "Alarm triggers when Shield Advanced detects a DDoS attack on production WAF"
}

resource "aws_cloudwatch_event_rule" "shield_ddos_rule" {
  count       = contains(["prod"], var.environment) ? 1 : 0
  name        = "${var.name_prefix}_shield_ddos_rules"
  description = "Forward DDoS alarm state change events to cross-account EventBridge bus"

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    resources     = [aws_cloudwatch_metric_alarm.shield_ddos_alarm[0].arn]
  })
}

resource "aws_cloudwatch_event_target" "shield_ddos_target" {
  count     = contains(["prod"], var.environment) ? 1 : 0

  rule      = aws_cloudwatch_event_rule.shield_ddos_rule[count.index].name
  target_id = "${var.name_prefix}-shield-ddos-target"
  arn       = "arn:aws:events:eu-west-2:${local.cross_account_id}:event-bus/shield-eventbus"
  role_arn  = aws_iam_role.eventbridge_role[count.index].arn
}
