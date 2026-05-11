output "key_arn" {
	description = "The Amazon Resource Name (ARN) of the key"
	value       = module.kms_key.key_arn
}

output "key_id" {
	description = "The globally unique identifier for the key"
	value       = module.kms_key.key_id
}

output "key_policy" {
	description = "The IAM resource policy set on the key"
	value       = module.kms_key.key_policy
}

output "key_region" {
	description = "The region for the key"
	value       = module.kms_key.key_region
}

output "aliases" {
	description = "A map of aliases created and their attributes"
	value       = module.kms_key.aliases
}

output "grants" {
	description = "A map of grants created and their attributes"
	value       = module.kms_key.grants
	sensitive   = true
}
