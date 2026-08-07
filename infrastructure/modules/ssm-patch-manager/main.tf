################################################################
# SSM Patch Manager
#
# Thin NHS wrapper around `cloudposse/ssm-patch-manager/aws` that
# keeps naming and tagging aligned with the shared `context.tf`
# pattern and enforces the screening platform's baseline controls:
#
#   * Creation gate via module.this.enabled
#   * Naming derived from module.this.id via CloudPosse context
#   * Tagging via module.this.tags via CloudPosse context
#   * S3 patch log output enabled by default
#   * Patch compliance level set to HIGH by default
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "ssm_patch_manager" {
  source  = "cloudposse/ssm-patch-manager/aws"
  version = "1.0.3"

  ################################################################
  # Patch baseline
  ################################################################

  operating_system                  = var.operating_system
  approved_patches_compliance_level = var.approved_patches_compliance_level
  patch_baseline_approval_rules     = var.patch_baseline_approval_rules
  ################################################################
  # Install maintenance window
  ################################################################

  install_maintenance_window_schedule = var.install_maintenance_window_schedule
  install_maintenance_window_duration = var.install_maintenance_window_duration
  install_maintenance_window_cutoff   = var.install_maintenance_window_cutoff
  install_maintenance_windows_targets = var.install_maintenance_windows_targets
  install_patch_groups                = var.install_patch_groups

  ################################################################
  # Scan maintenance window
  ################################################################

  scan_maintenance_window_schedule = var.scan_maintenance_window_schedule
  scan_maintenance_window_duration = var.scan_maintenance_window_duration
  scan_maintenance_window_cutoff   = var.scan_maintenance_window_cutoff
  scan_maintenance_windows_targets = var.scan_maintenance_windows_targets
  scan_patch_groups                = var.scan_patch_groups

  ################################################################
  # Task execution
  ################################################################

  reboot_option    = var.reboot_option
  service_role_arn = var.service_role_arn
  max_concurrency  = var.max_concurrency
  max_errors       = var.max_errors

  ################################################################
  # Logging
  ################################################################

  s3_log_output_enabled         = var.s3_log_output_enabled
  bucket_id                     = var.bucket_id
  s3_bucket_prefix_install_logs = var.s3_bucket_prefix_install_logs
  s3_bucket_prefix_scan_logs    = var.s3_bucket_prefix_scan_logs

  context = local.cloudposse_context
}
