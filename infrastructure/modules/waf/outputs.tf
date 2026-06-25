output "web_acl_arn" {
  description = "ARN of the WAF web ACL."
  value       = module.waf.arn
}

output "web_acl_id" {
  description = "ID of the WAF web ACL."
  value       = module.waf.id
}

output "web_acl_capacity" {
  description = "Current WAF capacity usage in WCUs."
  value       = module.waf.capacity
}

output "logging_config_id" {
  description = "ARN of the WAF logging configuration when logging is enabled."
  value       = module.waf.logging_config_id
}