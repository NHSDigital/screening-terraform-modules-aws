################################################################
# CloudWatch
#
# Thin NHS wrapper around the community CloudWatch submodules that
# provides a single entry point for the most common log and alarm
# building blocks used by screening teams:
#
#   * log-group
#   * log-stream
#   * log-metric-filter
#   * metric-alarm
#   * metric-alarms-by-multiple-dimensions
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  create = module.this.enabled && var.log_group != null

  name = local.log_group_name

  tags = module.this.tags
}

module "log_stream" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-stream"
  version = "5.7.2"

  create = module.this.enabled && var.log_stream != null

  name           = local.log_stream_name
  log_group_name = local.log_stream_log_group_name
}

module "log_metric_filter" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-metric-filter"
  version = "5.7.2"

  create_cloudwatch_log_metric_filter = module.this.enabled && var.log_metric_filter != null

  name           = local.log_metric_filter_name
  log_group_name = local.log_metric_filter_log_group_name
  pattern        = var.log_metric_filter.pattern

  metric_transformation_name      = var.log_metric_filter.metric_transformation_name
  metric_transformation_namespace = var.log_metric_filter.metric_transformation_namespace
}

module "metric_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  create_metric_alarm = module.this.enabled && var.metric_alarm != null

  alarm_name          = local.metric_alarm_name
  comparison_operator = var.metric_alarm.comparison_operator
  evaluation_periods  = var.metric_alarm.evaluation_periods
  threshold           = var.metric_alarm.threshold

  metric_name = local.metric_alarm_metric_name
  namespace   = local.metric_alarm_namespace
  period      = "60"
  statistic   = "Sum"

  tags = module.this.tags
}

module "metric_alarms_by_multiple_dimensions" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarms-by-multiple-dimensions"
  version = "5.7.2"

  create_metric_alarm = module.this.enabled && var.metric_alarms_by_multiple_dimensions != null

  alarm_name          = local.metric_alarms_by_multiple_dimensions_name
  comparison_operator = var.metric_alarms_by_multiple_dimensions.comparison_operator
  evaluation_periods  = var.metric_alarms_by_multiple_dimensions.evaluation_periods
  threshold           = var.metric_alarms_by_multiple_dimensions.threshold

  metric_name = local.metric_alarms_by_multiple_dimensions_metric_name
  namespace   = local.metric_alarms_by_multiple_dimensions_namespace
  period      = "60"
  statistic   = "Sum"
  dimensions  = var.metric_alarms_by_multiple_dimensions.dimensions

  tags = module.this.tags
}

check "log_stream_log_group_name" {
  assert {
    condition     = var.log_stream == null || var.log_group != null
    error_message = "log_stream requires log_group to be configured in the same module call."
  }
}

check "log_metric_filter_log_group_name" {
  assert {
    condition     = var.log_metric_filter == null || var.log_group != null
    error_message = "log_metric_filter requires log_group to be configured in the same module call."
  }
}

check "metric_alarm_metric_identity" {
  assert {
    condition     = var.metric_alarm == null || (local.metric_alarm_metric_name != null && local.metric_alarm_namespace != null)
    error_message = "metric_alarm requires metric_name and namespace, either directly on metric_alarm or indirectly from log_metric_filter."
  }
}

check "metric_alarms_by_multiple_dimensions_metric_identity" {
  assert {
    condition     = var.metric_alarms_by_multiple_dimensions == null || (local.metric_alarms_by_multiple_dimensions_metric_name != null && local.metric_alarms_by_multiple_dimensions_namespace != null)
    error_message = "metric_alarms_by_multiple_dimensions requires metric_name and namespace, either directly on metric_alarms_by_multiple_dimensions or indirectly from log_metric_filter."
  }
}