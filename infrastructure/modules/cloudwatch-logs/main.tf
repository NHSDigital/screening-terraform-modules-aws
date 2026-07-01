################################################################
# CloudWatch Logs
#
# Thin NHS wrapper around the community CloudWatch log-group and
# log-stream submodules that enforces screening platform baseline
# controls:
#
#   * Naming: derived from context labels via module.this.id
#   * Tagging: all NHS-required tags applied automatically
#   * Retention: configurable; defaults to 7 days
#   * Encryption: optional KMS key support
#   * Enabled flag: create = module.this.enabled
################################################################

module "log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  create = module.this.enabled && var.create_log_group

  name              = local.log_group_name
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id

  tags = module.this.tags
}

module "log_stream" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-stream"
  version = "5.7.2"

  create = module.this.enabled && var.create_log_stream && var.create_log_group

  name           = local.log_stream_name
  log_group_name = module.log_group.cloudwatch_log_group_name
}

check "log_stream_requires_log_group" {
  assert {
    condition     = !var.create_log_stream || var.create_log_group
    error_message = "create_log_stream requires create_log_group = true"
  }
}
