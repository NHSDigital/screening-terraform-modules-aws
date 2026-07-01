################################################################
# CloudWatch Log Metric Filter
#
# Thin NHS wrapper around the community CloudWatch log-metric-filter
# submodule that enforces screening platform baseline controls:
#
#   * Naming: derived from context + metric name
#   * Namespace: configurable or defaults to log group name
#   * Metric emission: triggered by log pattern matching
#   * Enabled flag: create = module.this.enabled
################################################################

module "log_metric_filter" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-metric-filter"
  version = "5.7.2"

  create_cloudwatch_log_metric_filter = module.this.enabled

  name           = local.filter_name
  log_group_name = var.log_group_name
  pattern        = var.pattern

  metric_transformation_name      = var.metric_transformation_name
  metric_transformation_namespace = local.metric_namespace
}

check "log_group_must_exist" {
  assert {
    condition     = var.log_group_name != ""
    error_message = "log_group_name is required and must not be empty."
  }
}
