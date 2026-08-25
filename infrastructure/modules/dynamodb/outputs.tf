output "table_arn" {
  description = "ARN of the DynamoDB table."
  value       = module.dynamodb_table.dynamodb_table_arn
}

output "table_id" {
  description = "ID (name) of the DynamoDB table."
  value       = module.dynamodb_table.dynamodb_table_id
}

output "table_name" {
  # DynamoDB table name and ID are the same value; this output exists for ergonomic caller access.
  description = "Name of the DynamoDB table (alias for table_id)."
  value       = module.dynamodb_table.dynamodb_table_id
}

output "table_stream_arn" {
  description = "ARN of the DynamoDB table stream. Empty string when streams are disabled."
  value       = module.dynamodb_table.dynamodb_table_stream_arn
}

output "table_stream_label" {
  description = "Timestamp of the DynamoDB table stream. Empty string when streams are disabled."
  value       = module.dynamodb_table.dynamodb_table_stream_label
}
