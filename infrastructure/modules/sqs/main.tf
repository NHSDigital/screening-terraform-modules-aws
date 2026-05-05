###########################
# SQS                     #
###########################

resource "aws_sqs_queue" "sqs_queue" {
  name                       = "${var.name_prefix}-${var.stack_name}"
  delay_seconds              = 0
  max_message_size           = 2048
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 120
  fifo_queue                 = false
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.queue.arn}\",\"maxReceiveCount\":4}"
  depends_on                 = [aws_sqs_queue.queue]
}

# Deadletter queue for messages that can't be delivered
resource "aws_sqs_queue" "queue" {
  name                        = "${var.name_prefix}-${var.stack_name}-deadletter-queue"
  delay_seconds               = 90
  max_message_size            = 2048
  message_retention_seconds   = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 120
  fifo_queue                  = false
  content_based_deduplication = false
}

resource "aws_sqs_queue_policy" "allow_sns_publish" {
  queue_url = aws_sqs_queue.sqs_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow-SNS-SendMessage"
        Effect = "Allow"

        Principal = {
          Service = "sns.amazonaws.com"
        }

        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.sqs_queue.arn

        Condition = {
          ArnLike = {
            "aws:SourceArn" = var.topic_arn
          }
        }
      }
    ]
  })
}
