output "inspector_assessment_target" {
  description = "The AWS Inspector assessment target."
  value       = module.inspector.inspector_assessment_target
}

output "aws_inspector_assessment_template" {
  description = "The AWS Inspector assessment template."
  value       = module.inspector.aws_inspector_assessment_template
}

output "aws_cloudwatch_event_rule" {
  description = "The CloudWatch event rule that triggers the Inspector assessment."
  value       = module.inspector.aws_cloudwatch_event_rule
}

output "aws_cloudwatch_event_target" {
  description = "The CloudWatch event target wiring the schedule to the Inspector assessment."
  value       = module.inspector.aws_cloudwatch_event_target
}
