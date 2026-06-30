locals {
  # CloudPosse modules expect namespace/stage/tenant context fields.
  # Map NHS context fields so generated resource names stay aligned with module.this.id.
  cloudposse_context = merge(module.this.context, {
    namespace = module.this.service
    stage     = module.this.environment
    tenant    = module.this.project
  })
}
