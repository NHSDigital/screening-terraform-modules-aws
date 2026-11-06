################################################################
# Input validation
################################################################

resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(var.include_filter) == 0 || length(var.exclude_filter) == 0
      error_message = "CloudWatch Metric Streams cannot use include_filter and exclude_filter together."
    }
  }
}
