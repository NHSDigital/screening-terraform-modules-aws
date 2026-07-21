################################################################
# Cross-variable validation constraints for CloudWatch Logs.
#
# These preconditions catch configuration patterns that are either
# inefficient or potentially problematic but would otherwise fail
# silently or produce unexpected behaviour.
################################################################

resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.log_group_class == null || var.log_group_class != "INFREQUENT_ACCESS" || var.retention_in_days > 30
      error_message = "INFREQUENT_ACCESS log group class only provides cost savings with retention > 30 days. Use STANDARD for shorter retention periods, or increase retention_in_days to >= 30."
    }

    precondition {
      condition     = var.skip_destroy == null || var.skip_destroy != true || var.retention_in_days >= 30
      error_message = "skip_destroy = true indicates data preservation intent; short retention (<30 days) may conflict with that goal. Consider increasing retention_in_days or setting skip_destroy = false."
    }

    precondition {
      condition     = var.log_group_name == null || can(regex("^/", var.log_group_name))
      error_message = "log_group_name must start with '/' to follow NHS naming convention (e.g., '/<service>/<project>/<environment>/<stack>/<name>')."
    }
  }
}
