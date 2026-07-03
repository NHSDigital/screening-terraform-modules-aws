################################################################
# CloudWatch Metric Alarms
#
# Thin NHS wrapper around the community CloudWatch metric-alarm and
# metric-alarms-by-multiple-dimensions submodules that enforces
# screening platform baseline controls:
#
#   * Naming: derived from context.id + alarm suffix
#   * Period: hardcoded to 60 seconds (enforced)
#   * Statistic: defaults to Sum (configurable per-alarm)
#   * Actions: SNS topic ARNs optional for notifications
#   * Enabled flag: create = module.this.enabled
################################################################

module "metric_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  create_metric_alarm = module.this.enabled && var.metric_alarm != null

  alarm_name          = local.single_alarm_name
  comparison_operator = var.metric_alarm.comparison_operator
  evaluation_periods  = var.metric_alarm.evaluation_periods
  threshold           = var.metric_alarm.threshold
  statistic           = var.metric_alarm.statistic
  period              = var.metric_alarm.period
  actions_enabled     = var.metric_alarm.actions_enabled

  metric_name = var.metric_alarm.metric_name
  namespace   = var.metric_alarm.namespace

  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions
  treat_missing_data        = var.treat_missing_data

  tags = module.this.tags
}

module "metric_alarms_by_multiple_dimensions" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarms-by-multiple-dimensions"
  version = "5.7.2"

  create_metric_alarm = module.this.enabled && var.metric_alarms_by_multiple_dimensions != null

  alarm_name          = local.multi_dimension_alarm_name
  comparison_operator = var.metric_alarms_by_multiple_dimensions.comparison_operator
  evaluation_periods  = var.metric_alarms_by_multiple_dimensions.evaluation_periods
  threshold           = var.metric_alarms_by_multiple_dimensions.threshold
  statistic           = var.metric_alarms_by_multiple_dimensions.statistic
  period              = var.metric_alarms_by_multiple_dimensions.period
  actions_enabled     = var.metric_alarms_by_multiple_dimensions.actions_enabled
  dimensions          = var.metric_alarms_by_multiple_dimensions.dimensions

  metric_name = var.metric_alarms_by_multiple_dimensions.metric_name
  namespace   = var.metric_alarms_by_multiple_dimensions.namespace

  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions
  treat_missing_data        = var.treat_missing_data

  tags = module.this.tags
}

check "at_least_one_alarm_configured" {
  assert {
    condition     = var.metric_alarm != null || var.metric_alarms_by_multiple_dimensions != null
    error_message = "At least one of metric_alarm or metric_alarms_by_multiple_dimensions must be configured."
  }
}
