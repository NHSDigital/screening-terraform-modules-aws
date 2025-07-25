output "cw_to_splunk_firehose_role_arn" {
  value = aws_iam_role.cloudwatch_to_firehose_role.arn
}

output "cw_to_splunk_firehose_stream_arn" {
  value = aws_kinesis_firehose_delivery_stream.cw_logs_splunk_stream.arn
}
