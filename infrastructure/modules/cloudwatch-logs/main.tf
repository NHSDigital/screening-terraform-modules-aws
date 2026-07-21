################################################################
# CloudWatch Logs
#
# Thin NHS wrapper around the community CloudWatch log-group and
# log-stream submodules that enforces screening platform baseline
# controls:
#
#   * Log group: always created; mandatory logging
#   * Naming: log group name derived from context or custom override
#   * Tagging: all NHS-required tags applied automatically
#   * Retention: configurable; defaults to 30 days
#   * Encryption: always enabled (KMS key optional)
#   * Streams: optional; created from stream_names list
#   * Enabled flag: creation gated via module.this.enabled
################################################################

module "log_group_label" {
  source = "../tags"

  # Allow forward slashes in log group names (e.g., /service/project/env/stack/name)
  regex_replace_chars = "/[^a-zA-Z0-9-_\\/]/"

  context = module.this.context
}

module "log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  create = module.log_group_label.enabled

  name              = local.log_group_name
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id
  log_group_class   = var.log_group_class
  skip_destroy      = var.skip_destroy

  tags = module.log_group_label.tags
}

module "log_stream" {
  for_each = module.log_group_label.enabled ? toset(var.stream_names) : toset([])

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-stream"
  version = "5.7.2"

  create         = true
  name           = each.value
  log_group_name = module.log_group.cloudwatch_log_group_name
}
