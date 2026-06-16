locals {
  log_group_name = module.this.id

  log_stream_name = format("%s-stream", module.this.id)

  log_metric_filter_name = format("%s-metric-filter", module.this.id)

  metric_alarm_name = format("%s-alarm", module.this.id)

  metric_alarms_by_multiple_dimensions_name = format("%s-dimension-alarm", module.this.id)
}

locals {
  created_log_group_name = length(trimspace(try(module.log_group.cloudwatch_log_group_name, ""))) > 0 ? module.log_group.cloudwatch_log_group_name : null

  log_stream_log_group_name = local.created_log_group_name

  log_metric_filter_log_group_name = local.created_log_group_name

  metric_alarm_metric_name = try(var.log_metric_filter.metric_transformation_name, null)

  metric_alarm_namespace = try(var.log_metric_filter.metric_transformation_namespace, null)

  metric_alarms_by_multiple_dimensions_metric_name = try(var.log_metric_filter.metric_transformation_name, null)

  metric_alarms_by_multiple_dimensions_namespace = try(var.log_metric_filter.metric_transformation_namespace, null)
}