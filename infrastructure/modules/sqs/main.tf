################################################################
# SQS queue
#
# Minimal NHS wrapper for a standard SQS queue used for event
# delivery workloads such as GitHub ARC workflow_job events.
#
#   * Standard queue only
#   * SQS-managed server-side encryption enabled
#   * Optional dead-letter queue with redrive policy
#   * Optional publisher policy statements limited to SendMessage
#   * Queue policy denies insecure transport
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

resource "aws_sqs_queue" "dead_letter" {
  count = module.this.enabled && var.dead_letter_queue.create ? 1 : 0

  name                       = local.dead_letter_queue_name
  visibility_timeout_seconds = local.dead_letter_visibility_timeout_seconds
  message_retention_seconds  = var.dead_letter_queue.message_retention_seconds
  receive_wait_time_seconds  = var.dead_letter_queue.receive_wait_time_seconds
  sqs_managed_sse_enabled    = true

  tags = module.this.tags
}

resource "aws_sqs_queue" "this" {
  count = module.this.enabled ? 1 : 0

  name                       = local.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  sqs_managed_sse_enabled    = true

  redrive_policy = var.dead_letter_queue.create ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter[0].arn
    maxReceiveCount     = var.dead_letter_queue.max_receive_count
  }) : null

  tags = module.this.tags
}

resource "aws_sqs_queue_policy" "this" {
  count = module.this.enabled ? 1 : 0

  queue_url = aws_sqs_queue.this[0].id
  policy    = data.aws_iam_policy_document.queue[0].json
}
