locals {
  visibility_config = var.visibility_config != null ? var.visibility_config : {
    cloudwatch_metrics_enabled = true
    metric_name                = module.this.id
    sampled_requests_enabled   = true
  }

  # Cloud Posse modules expect namespace/stage/tenant context fields.
  # Map NHS labels to Cloud Posse equivalents:
  # - namespace (Cloud Posse) = service (NHS)
  # - stage (Cloud Posse) = stack (NHS); do NOT use environment, which is a separate label
  # - tenant (Cloud Posse) = project (NHS)
  # Use the caller's custom label_order if provided, otherwise the cloudposse-compatible default.
  cloudposse_context = merge(module.this.context, {
    namespace   = module.this.service
    stage       = module.this.stack
    tenant      = module.this.project
    label_order = var.label_order != null ? module.this.label_order : ["namespace", "environment", "stage", "name", "attributes"]
  })

}
