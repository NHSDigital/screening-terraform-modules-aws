output "web_acl_arn" {
  description = "ARN of the WAFv2 web ACL."
  value       = aws_wafv2_web_acl.bss-waf-acl.arn
}
