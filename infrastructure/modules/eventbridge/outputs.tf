output "eventbridge_bus_name" {
  description = "The EventBridge Bus Name"
  value       = module.eventbridge.eventbridge_bus_name
}

output "eventbridge_bus_arn" {
  description = "The EventBridge Bus ARN"
  value       = module.eventbridge.eventbridge_bus_arn
}

output "eventbridge_archive_arns" {
  description = "The EventBridge Archive ARNs"
  value       = module.eventbridge.eventbridge_archive_arns
}

output "eventbridge_permission_ids" {
  description = "The EventBridge Permission IDs"
  value       = module.eventbridge.eventbridge_permission_ids
}

output "eventbridge_connection_ids" {
  description = "The EventBridge Connection IDs"
  value       = module.eventbridge.eventbridge_connection_ids
}

output "eventbridge_connection_arns" {
  description = "The EventBridge Connection Arns"
  value       = module.eventbridge.eventbridge_connection_arns
}

output "eventbridge_api_destination_arns" {
  description = "The EventBridge API Destination ARNs"
  value       = module.eventbridge.eventbridge_api_destination_arns
}

output "eventbridge_rule_ids" {
  description = "The EventBridge Rule IDs"
  value       = module.eventbridge.eventbridge_rule_ids
}

output "eventbridge_rule_arns" {
  description = "The EventBridge Rule ARNs"
  value       = module.eventbridge.eventbridge_rule_arns
}

output "eventbridge_schedule_group_ids" {
  description = "The EventBridge Schedule Group IDs"
  value       = module.eventbridge.eventbridge_schedule_group_ids
}

output "eventbridge_schedule_group_arns" {
  description = "The EventBridge Schedule Group ARNs"
  value       = module.eventbridge.eventbridge_schedule_group_arns
}

output "eventbridge_schedule_group_states" {
  description = "The EventBridge Schedule Group states"
  value       = module.eventbridge.eventbridge_schedule_group_states
}

output "eventbridge_schedule_ids" {
  description = "The EventBridge Schedule IDs created"
  value       = module.eventbridge.eventbridge_schedule_ids
}

output "eventbridge_schedule_arns" {
  description = "The EventBridge Schedule ARNs created"
  value       = module.eventbridge.eventbridge_schedule_arns
}

output "eventbridge_role_arn" {
  description = "The ARN of the IAM role created for EventBridge"
  value       = module.eventbridge.eventbridge_role_arn
}

output "eventbridge_role_name" {
  description = "The name of the IAM role created for EventBridge"
  value       = module.eventbridge.eventbridge_role_name
}

output "eventbridge_pipe_ids" {
  description = "The EventBridge Pipes IDs"
  value       = module.eventbridge.eventbridge_pipe_ids
}

output "eventbridge_pipe_arns" {
  description = "The EventBridge Pipes ARNs"
  value       = module.eventbridge.eventbridge_pipe_arns
}

output "eventbridge_pipe_role_arns" {
  description = "The ARNs of the IAM role created for EventBridge Pipes"
  value       = module.eventbridge.eventbridge_pipe_role_arns
}

output "eventbridge_pipe_role_names" {
  description = "The names of the IAM role created for EventBridge Pipes"
  value       = module.eventbridge.eventbridge_pipe_role_names
}

output "eventbridge_bus" {
  description = "The EventBridge Bus created and their attributes"
  value       = module.eventbridge.eventbridge_bus
}

output "eventbridge_archives" {
  description = "The EventBridge Archives created and their attributes"
  value       = module.eventbridge.eventbridge_archives
}

output "eventbridge_permissions" {
  description = "The EventBridge Permissions created and their attributes"
  value       = module.eventbridge.eventbridge_permissions
}

output "eventbridge_connections" {
  description = "The EventBridge Connections created and their attributes"
  value       = module.eventbridge.eventbridge_connections
  sensitive   = true
}

output "eventbridge_api_destinations" {
  description = "The EventBridge API Destinations created and their attributes"
  value       = module.eventbridge.eventbridge_api_destinations
}

output "eventbridge_targets" {
  description = "The EventBridge Targets created and their attributes"
  value       = module.eventbridge.eventbridge_targets
}

output "eventbridge_rules" {
  description = "The EventBridge Rules created and their attributes"
  value       = module.eventbridge.eventbridge_rules
}

output "eventbridge_schedule_groups" {
  description = "The EventBridge Schedule Groups created and their attributes"
  value       = module.eventbridge.eventbridge_schedule_groups
}

output "eventbridge_schedules" {
  description = "The EventBridge Schedules created and their attributes"
  value       = module.eventbridge.eventbridge_schedules
}

output "eventbridge_pipes" {
  description = "The EventBridge Pipes created and their attributes"
  value       = module.eventbridge.eventbridge_pipes
}

output "eventbridge_log_delivery_source_arn" {
  description = "The EventBridge Bus CloudWatch Log Delivery Source ARN"
  value       = module.eventbridge.eventbridge_log_delivery_source_arn
}

output "eventbridge_log_delivery_source_name" {
  description = "The EventBridge Bus CloudWatch Log Delivery Source Name"
  value       = module.eventbridge.eventbridge_log_delivery_source_name
}

output "eventbridge_pipes_iam_roles" {
  description = "The EventBridge Pipes IAM roles created and their attributes"
  value       = module.eventbridge.eventbridge_pipes_iam_roles
}

output "eventbridge_iam_roles" {
  description = "The EventBridge IAM roles created and their attributes"
  value       = module.eventbridge.eventbridge_iam_roles
}
