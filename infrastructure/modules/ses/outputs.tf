output "ses_domain_identity_arn" {
  description = "The ARN of the SES domain identity."
  value       = module.ses.ses_domain_identity_arn
}

output "ses_domain_identity_verification_token" {
  description = "The TXT record value to add to your DNS zone to verify SES domain ownership. Only required when zone_id is not provided and verify_domain is managed externally."
  value       = module.ses.ses_domain_identity_verification_token
}

output "ses_dkim_tokens" {
  description = "List of DKIM tokens to add as CNAME records in your DNS zone to enable DKIM signing. Only required when zone_id is not provided and verify_dkim is managed externally."
  value       = module.ses.ses_dkim_tokens
}

output "spf_record" {
  description = "The SPF TXT record value. Add this to your DNS zone when create_spf_record is false and you manage DNS records externally."
  value       = module.ses.spf_record
}

output "custom_from_domain" {
  description = "The custom MAIL FROM domain (e.g. mail.example.nhs.uk). Empty when custom_from_subdomain is not set."
  value       = module.ses.custom_from_domain
}

output "user_arn" {
  description = "The ARN of the IAM user created for SES sending. Empty when ses_user_enabled is false."
  value       = module.ses.user_arn
}

output "user_name" {
  description = "The name of the IAM user created for SES sending. Empty when ses_user_enabled is false."
  value       = module.ses.user_name
}

output "ses_group_name" {
  description = "The name of the IAM group created for SES sending. Empty when ses_group_enabled is false."
  value       = module.ses.ses_group_name
}
