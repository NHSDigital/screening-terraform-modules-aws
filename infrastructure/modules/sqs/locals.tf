locals {
  queue_name = module.this.enabled ? coalesce(var.custom_name, module.this.id) : ""

  dead_letter_queue_name = "${local.queue_name}-dlq"

  dead_letter_visibility_timeout_seconds = coalesce(
    var.dead_letter_queue.visibility_timeout_seconds,
    var.visibility_timeout_seconds
  )
}
