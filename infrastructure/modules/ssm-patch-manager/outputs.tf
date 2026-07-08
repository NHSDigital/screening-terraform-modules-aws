output "patch_baseline_arn" {
  description = "ARN of the SSM patch baseline."
  value       = module.ssm_patch_manager.patch_baseline_arn
}

output "install_maintenance_window_id" {
  description = "ID of the SSM install maintenance window."
  value       = module.ssm_patch_manager.install_maintenance_window_id
}

output "install_maintenance_window_target_id" {
  description = "ID of the install maintenance window target."
  value       = module.ssm_patch_manager.install_maintenance_window_target_id
}

output "install_maintenance_window_task_id" {
  description = "ID of the install maintenance window task."
  value       = module.ssm_patch_manager.install_maintenance_window_task_id
}

output "install_patch_group_id" {
  description = "ID of the install patch group."
  value       = module.ssm_patch_manager.install_patch_group_id
}

output "scan_maintenance_window_target_id" {
  description = "ID of the scan maintenance window target."
  value       = module.ssm_patch_manager.scan_maintenance_window_target_id
}

output "scan_maintenance_window_task_id" {
  description = "ID of the scan maintenance window task."
  value       = module.ssm_patch_manager.scan_maintenance_window_task_id
}

output "scan_patch_group_id" {
  description = "ID of the scan patch group."
  value       = module.ssm_patch_manager.scan_patch_group_id
}

output "ssm_patch_log_s3_bucket_arn" {
  description = "ARN of the S3 bucket used for patch logs. Empty when bucket_id is supplied."
  value       = module.ssm_patch_manager.ssm_patch_log_s3_bucket_arn
}

output "ssm_patch_log_s3_bucket_id" {
  description = "ID of the S3 bucket used for patch logs. Empty when bucket_id is supplied."
  value       = module.ssm_patch_manager.ssm_patch_log_s3_bucket_id
}
