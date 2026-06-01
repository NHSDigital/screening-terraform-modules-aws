output "license_configuration_arn" {
  description = "ARN of the License Manager license configuration."
  value       = try(aws_licensemanager_license_configuration.this[0].arn, null)
}

output "license_configuration_id" {
  description = "ID (ARN) of the License Manager license configuration."
  value       = try(aws_licensemanager_license_configuration.this[0].id, null)
}

output "owner_account_id" {
  description = "AWS account ID that owns the license configuration."
  value       = try(aws_licensemanager_license_configuration.this[0].owner_account_id, null)
}

output "association_ids" {
  description = "Map of license configuration associations keyed by the caller-supplied identifier, with the association ID as the value."
  value       = { for k, v in aws_licensemanager_association.this : k => v.id }
}
