resource "aws_iam_policy" "cloudwatch_to_firehose" {
  name        = "${var.name_prefix}-CloudWatchToFirehosePolicy"
  description = "Policy to allow CloudWatch to deliver logs to Kinesis Firehose"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = aws_kinesis_firehose_delivery_stream.cw_logs_splunk_stream.arn
      }
    ]
  })
}

resource "aws_iam_role" "cloudwatch_to_firehose_role" {
  name = "${var.name_prefix}-CloudWatchToFirehoseRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_to_firehose_attachment" {
  role       = aws_iam_role.cloudwatch_to_firehose_role.name
  policy_arn = aws_iam_policy.cloudwatch_to_firehose.arn
}
