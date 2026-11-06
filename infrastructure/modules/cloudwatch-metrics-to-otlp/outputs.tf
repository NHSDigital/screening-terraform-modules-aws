output "metric_stream_arn" {
  description = "ARN of the CloudWatch metric stream."
  value       = module.metric_stream.metric_stream_arn
}

output "firehose_arn" {
  description = "ARN of the Firehose delivery stream."
  value       = module.firehose.delivery_stream_arn
}

output "forwarder_lambda_arn" {
  description = "ARN of the OTLP metrics forwarder Lambda."
  value       = module.forwarder.lambda_arn
}

output "failure_bucket_arn" {
  description = "ARN of the private S3 bucket used by Firehose for retained and failed records."
  value       = module.failure_bucket.bucket_arn
}
