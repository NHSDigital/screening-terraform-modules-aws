output "security_group_arn" {
  description = "The ARN of the security group"
  value       = module.security_group.arn
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = module.security_group.id
}

output "security_group_name" {
  description = "The name of the security group"
  value       = module.security_group.name
}

output "security_group_owner_id" {
  description = "The owner ID"
  value       = module.security_group.owner_id
}

output "security_group_vpc_id" {
  description = "The ID of the VPC used by the security group"
  value       = module.security_group.vpc_id
}
