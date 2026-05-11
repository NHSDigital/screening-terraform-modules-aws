output "detector_id" {
  description = "The ID of the GuardDuty detector."
  value       = aws_guardduty_detector.this.id
}

output "detector_arn" {
  description = "The ARN of the GuardDuty detector."
  value       = aws_guardduty_detector.this.arn
}

output "cloudwatch_event_rule_arn" {
  description = "ARN of the CloudWatch (EventBridge) rule forwarding GuardDuty findings, if created."
  value       = try(aws_cloudwatch_event_rule.findings[0].arn, null)
}
