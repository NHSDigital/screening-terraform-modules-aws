################################################################
# Security Hub
#
# Enables AWS Security Hub in the current account/region,
# subscribes to the requested standards, optionally enables
# cross-region finding aggregation, and (optionally) wires
# imported findings to an existing SNS topic via EventBridge.
#
# This pairs with the GuardDuty module: GuardDuty findings are
# automatically ingested by Security Hub once both services are
# enabled in the same account/region.
################################################################

data "aws_partition" "current" {}
data "aws_region" "current" {}

################################################################
# Account-level Security Hub enablement
################################################################

resource "aws_securityhub_account" "this" {
  count = module.this.enabled ? 1 : 0

  enable_default_standards  = var.enable_default_standards
  control_finding_generator = var.control_finding_generator
  auto_enable_controls      = var.auto_enable_controls
}

################################################################
# Standards subscriptions
################################################################

locals {
  standards_arns = {
    for s in var.enabled_standards :
    s => startswith(s, "arn:") ? s : format(
      "arn:%s:securityhub:%s::%s",
      data.aws_partition.current.partition,
      data.aws_region.current.name,
      s,
    )
  }
}

resource "aws_securityhub_standards_subscription" "this" {
  for_each = module.this.enabled ? local.standards_arns : {}

  standards_arn = each.value

  depends_on = [aws_securityhub_account.this]
}

################################################################
# Finding aggregator (cross-region aggregation)
################################################################

resource "aws_securityhub_finding_aggregator" "this" {
  count = module.this.enabled && var.finding_aggregator_enabled ? 1 : 0

  linking_mode = var.finding_aggregator_linking_mode
  specified_regions = contains(
    ["SPECIFIED_REGIONS", "ALL_REGIONS_EXCEPT_SPECIFIED"],
    var.finding_aggregator_linking_mode,
  ) ? var.finding_aggregator_regions : null

  depends_on = [aws_securityhub_account.this]

  lifecycle {
    precondition {
      condition = !contains(
        ["SPECIFIED_REGIONS", "ALL_REGIONS_EXCEPT_SPECIFIED"],
        var.finding_aggregator_linking_mode,
      ) || length(var.finding_aggregator_regions) > 0
      error_message = "finding_aggregator_regions must be set when finding_aggregator_linking_mode is SPECIFIED_REGIONS or ALL_REGIONS_EXCEPT_SPECIFIED."
    }
  }
}

################################################################
# CloudWatch Event Rule -> SNS forwarding for imported findings
#
# The SNS topic itself is created by the separate alerting module.
# Pass the topic ARN via `findings_notification_arn` to wire
# imported Security Hub findings into it.
################################################################

# Sub-label for the imported-findings EventBridge rule so its
# name/tags are derived from the same context but disambiguated
# from the account-level resources.
module "imported_findings_label" {
  source  = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags?ref=feature/BCSS-23189-add-new-modules-to-suppport-bcss"
  context = module.this.context

  attributes = concat(module.this.attributes, ["imported-findings"])
}

resource "aws_cloudwatch_event_rule" "imported_findings" {
  count = module.this.enabled && var.enable_cloudwatch ? 1 : 0

  name        = module.imported_findings_label.id
  description = "Forward Security Hub imported findings to SNS for alerting."

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = [var.cloudwatch_event_rule_pattern_detail_type]
  })

  tags = module.imported_findings_label.tags
}

resource "aws_cloudwatch_event_target" "imported_findings" {
  count = module.this.enabled && var.enable_cloudwatch && var.findings_notification_arn != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.imported_findings[0].name
  target_id = module.imported_findings_label.id
  arn       = var.findings_notification_arn
}
