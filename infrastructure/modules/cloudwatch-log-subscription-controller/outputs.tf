output "controller_function_arn" {
  description = "ARN of the Lambda function that enrols future matching log groups."
  value       = module.this.enabled ? module.controller.lambda_arn : null
}

output "event_rule_arn" {
  description = "ARN of the EventBridge rule that receives CreateLogGroup API events."
  value       = try(module.eventbridge.eventbridge_rule_arns[local.eventbridge_rule_key], null)
}
