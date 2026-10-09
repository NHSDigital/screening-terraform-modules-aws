locals {
  single_alarm_name          = format("%s-alarm", module.this.id)
  multi_dimension_alarm_name = format("%s-malarm", module.this.id)

  single_metric_alarm = var.metric_alarm != null ? var.metric_alarm : {
    metric_name         = "disabled"
    namespace           = "disabled"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 0
    statistic           = "Sum"
    period              = 60
    actions_enabled     = false
  }

  multi_dimension_metric_alarm = var.metric_alarms_by_multiple_dimensions != null ? var.metric_alarms_by_multiple_dimensions : {
    metric_name         = "disabled"
    namespace           = "disabled"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 0
    statistic           = "Sum"
    period              = 60
    actions_enabled     = false
    dimensions          = {}
  }
}
