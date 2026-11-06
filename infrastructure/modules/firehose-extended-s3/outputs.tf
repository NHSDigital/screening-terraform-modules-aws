output "delivery_stream_arn" {
  description = "ARN of the Firehose delivery stream."
  value       = try(aws_kinesis_firehose_delivery_stream.this[0].arn, null)
}

output "delivery_stream_name" {
  description = "Name of the Firehose delivery stream."
  value       = try(aws_kinesis_firehose_delivery_stream.this[0].name, null)
}
