output "arn" {
  description = "ARN of the load balancer. Used by WAF to associate a Web ACL."
  value       = module.alb.arn
}

output "dns_name" {
  description = "DNS name of the load balancer. Used by Route53 alias records."
  value       = module.alb.dns_name
}

output "zone_id" {
  description = "Hosted zone ID of the load balancer. Used by Route53 alias records."
  value       = module.alb.zone_id
}

output "id" {
  description = "ID of the load balancer (same as ARN)."
  value       = module.alb.id
}

output "arn_suffix" {
  description = "ARN suffix of the load balancer. Used with CloudWatch metrics."
  value       = module.alb.arn_suffix
}

output "listeners" {
  description = "Map of listeners created and their attributes. ECS tasks use this for depends_on."
  value       = module.alb.listeners
}

output "target_groups" {
  description = "Map of target groups created and their attributes. ECS tasks reference target_group ARNs from here."
  value       = module.alb.target_groups
}

output "security_group_id" {
  description = "ID of the security group created for the load balancer."
  value       = module.alb.security_group_id
}

output "security_group_arn" {
  description = "ARN of the security group created for the load balancer."
  value       = module.alb.security_group_arn
}
