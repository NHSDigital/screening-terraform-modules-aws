locals {
  visibility_config = var.visibility_config != null ? var.visibility_config : {
    cloudwatch_metrics_enabled = true
    metric_name                = module.this.id
    sampled_requests_enabled   = true
  }

  # Cloud Posse modules expect namespace/stage/tenant context fields.
  cloudposse_context = merge(module.this.context, {
    namespace = module.this.service
    stage     = module.this.environment
    tenant    = module.this.project
  })
}
