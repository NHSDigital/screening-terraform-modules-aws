output "cluster_arn" {
  description = "ARN that identifies the ECS cluster."
  value       = module.ecs_cluster.arn
}

output "cluster_id" {
  description = "ID that identifies the ECS cluster."
  value       = module.ecs_cluster.id
}

output "cluster_name" {
  description = "Name that identifies the ECS cluster."
  value       = module.ecs_cluster.name
}

output "cluster_capacity_providers" {
  description = "Map of cluster capacity provider attributes."
  value       = module.ecs_cluster.cluster_capacity_providers
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name used for ECS Exec logs when enabled."
  value       = module.ecs_cluster.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN used for ECS Exec logs when enabled."
  value       = module.ecs_cluster.cloudwatch_log_group_arn
}
