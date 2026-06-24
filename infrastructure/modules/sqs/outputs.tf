output "arn" {
  description = "ARN of the primary SQS queue."
  value       = aws_sqs_queue.sqs_queue.arn
}
