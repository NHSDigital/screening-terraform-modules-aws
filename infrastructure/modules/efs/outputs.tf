output "efs_id" {
  description = "The ID of the EFS file system."
  value       = module.efs.id
}

output "efs_arn" {
  description = "The Amazon Resource Name (ARN) of the EFS file system."
  value       = module.efs.arn
}

output "efs_dns_name" {
  description = "The DNS name of the EFS file system."
  value       = module.efs.dns_name
}

output "efs_size_in_bytes" {
  description = "The latest metered size of the EFS in bytes."
  value       = module.efs.size_in_bytes
}

output "efs_encrypted" {
  description = "Always true; encryption is enforced by this module."
  value       = true
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encryption."
  value       = var.kms_key_arn
}

output "mount_targets" {
  description = "Map of mount target IDs and their associated subnet IDs."
  value       = module.efs.mount_targets
}

output "replication_configuration" {
  description = "The replication configuration of the EFS file system, if enabled."
  value       = try(module.efs.replication_configuration_destination_file_system_id, null)
}

output "file_system_policy_id" {
  description = "The file system policy ID (if policy was attached)."
  value       = try(aws_efs_file_system_policy.this[0].id, null)
}

output "access_points" {
  description = "Map of EFS Access Point IDs and their ARNs, keyed by the input map keys."
  value       = { for k, ap in aws_efs_access_point.this : k => { id = ap.id, arn = ap.arn } }
}
