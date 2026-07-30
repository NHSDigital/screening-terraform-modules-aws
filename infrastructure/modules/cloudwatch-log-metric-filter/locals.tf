locals {
  metric_namespace = var.metric_transformation_namespace != "" ? var.metric_transformation_namespace : var.log_group_name
  filter_name      = format("%s-%s", module.this.id, var.metric_transformation_name)
}
