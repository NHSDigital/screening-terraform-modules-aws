################################################################
# GuardDuty Detector
################################################################

resource "aws_guardduty_detector" "this" {
  count = module.this.enabled && var.enable_detector ? 1 : 0

  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  tags = module.this.tags
}

################################################################
# Detector Features
#
# All feature toggles use the newer aws_guardduty_detector_feature
# resource
################################################################

resource "aws_guardduty_detector_feature" "s3_data_events" {
  count = module.this.enabled && var.enable_detector ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "S3_DATA_EVENTS"
  status      = var.s3_protection_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "eks_audit_logs" {
  count = module.this.enabled && var.enable_detector ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "EKS_AUDIT_LOGS"
  status      = var.kubernetes_audit_logs_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "ebs_malware_protection" {
  count = module.this.enabled && var.enable_detector ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "EBS_MALWARE_PROTECTION"
  status      = var.malware_protection_scan_ec2_ebs_volumes_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "lambda_network_logs" {
  count = module.this.enabled && var.enable_detector ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = var.lambda_network_logs_enabled ? "ENABLED" : "DISABLED"
}

# Runtime Monitoring (EC2 + ECS + EKS). Mutually exclusive with
# eks_runtime_monitoring_enabled — guarded by the precondition below.
resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  count = module.this.enabled && var.enable_detector ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "RUNTIME_MONITORING"
  status      = var.runtime_monitoring_enabled ? "ENABLED" : "DISABLED"

  dynamic "additional_configuration" {
    for_each = var.runtime_monitoring_enabled ? [1] : []
    content {
      name   = "EKS_ADDON_MANAGEMENT"
      status = var.runtime_monitoring_additional_config.eks_addon_management_enabled ? "ENABLED" : "DISABLED"
    }
  }

  dynamic "additional_configuration" {
    for_each = var.runtime_monitoring_enabled ? [1] : []
    content {
      name   = "ECS_FARGATE_AGENT_MANAGEMENT"
      status = var.runtime_monitoring_additional_config.ecs_fargate_agent_management_enabled ? "ENABLED" : "DISABLED"
    }
  }

  dynamic "additional_configuration" {
    for_each = var.runtime_monitoring_enabled ? [1] : []
    content {
      name   = "EC2_AGENT_MANAGEMENT"
      status = var.runtime_monitoring_additional_config.ec2_agent_management_enabled ? "ENABLED" : "DISABLED"
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.runtime_monitoring_enabled && var.eks_runtime_monitoring_enabled)
      error_message = "runtime_monitoring_enabled and eks_runtime_monitoring_enabled are mutually exclusive. RUNTIME_MONITORING already covers EKS."
    }
  }
}

# Standalone EKS Runtime Monitoring (only enable when RUNTIME_MONITORING is off).
resource "aws_guardduty_detector_feature" "eks_runtime_monitoring" {
  count = module.this.enabled && var.enable_detector ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "EKS_RUNTIME_MONITORING"
  status      = var.eks_runtime_monitoring_enabled ? "ENABLED" : "DISABLED"

  dynamic "additional_configuration" {
    for_each = var.eks_runtime_monitoring_enabled ? [1] : []
    content {
      name   = "EKS_ADDON_MANAGEMENT"
      status = var.runtime_monitoring_additional_config.eks_addon_management_enabled ? "ENABLED" : "DISABLED"
    }
  }
}

################################################################
# CloudWatch Event Rule -> SNS forwarding for findings
#
# The SNS topic itself is created by the separate alerting module.
# Pass the topic ARN via `findings_notification_arn` to wire findings into it.
################################################################

# Sub-label for the findings EventBridge rule so its name/tags
# are derived from the same context but disambiguated from the
# detector.
module "findings_label" {
  source  = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags?ref=v4.1.0"
  context = module.this.context

  attributes = concat(module.this.attributes, ["findings"])
}

resource "aws_cloudwatch_event_rule" "findings" {
  count = module.this.enabled && var.enable_cloudwatch ? 1 : 0

  name        = module.findings_label.id
  description = "Forward GuardDuty findings to SNS for alerting."

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = [var.cloudwatch_event_rule_pattern_detail_type]
  })

  tags = module.findings_label.tags
}

resource "aws_cloudwatch_event_target" "findings" {
  # Do not gate count on ARN nullability because callers often pass a
  # module output ARN that is unknown until apply.
  count = module.this.enabled && var.enable_cloudwatch ? 1 : 0

  rule      = aws_cloudwatch_event_rule.findings[0].name
  target_id = module.findings_label.id
  arn       = var.findings_notification_arn
}
