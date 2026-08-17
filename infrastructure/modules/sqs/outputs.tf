output "queue_id" {
  description = "The ID of the primary queue. For SQS this is the queue URL identifier."
  value       = try(aws_sqs_queue.this[0].id, null)
}

output "queue_arn" {
  description = "The ARN of the primary queue."
  value       = try(aws_sqs_queue.this[0].arn, null)
}

output "queue_url" {
  description = "The URL of the primary queue."
  value       = try(aws_sqs_queue.this[0].id, null)
}

output "queue_name" {
  description = "The name of the primary queue."
  value       = module.this.enabled ? local.queue_name : null
}

output "dlq_arn" {
  description = "The ARN of the dead-letter queue when created, otherwise null."
  value       = try(aws_sqs_queue.dead_letter[0].arn, null)
}
