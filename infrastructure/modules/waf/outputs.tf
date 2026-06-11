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

output "legacy_exclude_ip_set_arn" {
  description = "ARN of the legacy BCSS excluded IP set when created."
  value       = try(aws_wafv2_ip_set.legacy_exclude[0].arn, null)
}

output "legacy_webservices_ip_set_arn" {
  description = "ARN of the legacy BCSS webservices allowlist IP set when created."
  value       = try(aws_wafv2_ip_set.legacy_webservices[0].arn, null)
}

output "waf_log_group_name" {
  description = "Name of the WAF CloudWatch log group when created by this module."
  value       = try(aws_cloudwatch_log_group.waf_logs[0].name, null)
}
