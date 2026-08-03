################################################################
# SES Domain Identity
#
# Thin NHS wrapper around cloudposse/ses/aws that enforces the
# screening platform's baseline controls:
#
#   * IAM credentials:    access keys never written to Terraform state
#   * SMTP passwords:     never written to Terraform state
#   * IAM user/group:     always disabled; ECS tasks use IAM roles instead
#   * Tagging:            all NHS-required tags applied automatically
#   * Enabled flag:       enabled = module.this.enabled
#
# Inputs intentionally NOT exposed (hardcoded below):
#   - iam_create_access_key        → always false; credentials must not be stored in state
#   - iam_create_ses_smtp_password → always false; credentials must not be stored in state
#   - ses_user_enabled             → always false; use ECS task IAM roles for sending
#   - ses_group_enabled            → always false; use ECS task IAM roles for sending
#   - custom_from_behavior_on_mx_failure → UseDefaultValue (sensible default, not exposed)
#
# Cross-variable input constraints are enforced in validations.tf.
#
# NOTE: This module requires the cloudposse/awsutils provider to be
# configured in the calling stack because the cloudposse/ses upstream
# module declares it as a required provider.
################################################################

module "ses" {
  source  = "cloudposse/ses/aws"
  version = "0.25.2"

  enabled = module.this.enabled

  # SES domain identity — the domain itself is the primary resource name
  domain  = var.domain
  zone_id = var.zone_id

  # DNS verification records (require zone_id)
  verify_domain     = var.verify_domain
  verify_dkim       = var.verify_dkim
  create_spf_record = var.create_spf_record

  # Custom MAIL FROM domain
  custom_from_subdomain          = var.custom_from_subdomain
  custom_from_dns_record_enabled = var.custom_from_dns_record_enabled

  # IAM — hardcoded off; ECS services authenticate via task IAM roles, not IAM users.
  ses_user_enabled  = false # hardcoded — use ECS task roles for sending permissions
  ses_group_enabled = false # hardcoded — use ECS task roles for sending permissions

  # Security baseline: IAM credentials must never be stored in Terraform state.
  iam_create_access_key        = false # hardcoded — access keys in state are prohibited
  iam_create_ses_smtp_password = false # hardcoded — SMTP passwords in state are prohibited

  # Tags — automatically populated from context
  tags = module.this.tags
}
