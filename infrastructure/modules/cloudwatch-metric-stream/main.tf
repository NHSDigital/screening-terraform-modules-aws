################################################################
# CloudWatch metric stream
#
# Thin NHS wrapper around the community metric-stream submodule.
# Naming, tagging, and creation gating use module.this.
################################################################

module "metric_stream" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-stream"
  version = "6.0.0"

  create = module.this.enabled

  name                     = coalesce(var.stream_name, module.this.id)
  firehose_arn             = var.firehose_arn
  role_arn                 = var.role_arn
  output_format            = var.output_format
  include_filter           = var.include_filter
  exclude_filter           = var.exclude_filter
  statistics_configuration = var.statistics_configuration
  tags                     = module.this.tags
}
