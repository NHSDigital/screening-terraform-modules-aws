################################################################
# Queue configuration
################################################################

variable "custom_name" {
  description = "Optional explicit queue name. When null, the queue name is derived from module.this.id."
  type        = string
  default     = null

  validation {
    condition     = var.custom_name == null || can(regex("^[A-Za-z0-9_-]{1,76}$", var.custom_name))
    error_message = "custom_name must be null or contain only letters, numbers, hyphens, and underscores, with a maximum length of 76 characters to allow an optional '-dlq' suffix."
  }
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the primary queue in seconds."
  type        = number
  default     = 300

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "visibility_timeout_seconds must be between 0 and 43200."
  }
}

variable "message_retention_seconds" {
  description = "Message retention period for the primary queue in seconds."
  type        = number
  default     = 345600

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds must be between 60 and 1209600."
  }
}

variable "receive_wait_time_seconds" {
  description = "Receive wait time for long polling on the primary queue in seconds."
  type        = number
  default     = 20

  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "receive_wait_time_seconds must be between 0 and 20."
  }
}

################################################################
# Publisher access
################################################################

variable "publisher_statements" {
  description = <<-EOT
    Optional queue policy statements that allow publishers to send messages.
    Each statement is constrained to `sqs:SendMessage` on this queue.

    Example:
      publisher_statements = {
        github_events = {
          principals = {
            type        = "Service"
            identifiers = ["events.amazonaws.com"]
          }
          source_arns = ["arn:aws:events:eu-west-2:123456789012:rule/github-arc"]
        }
      }
  EOT
  type = map(object({
    principals = object({
      type        = string
      identifiers = list(string)
    })
    source_arns     = optional(list(string), [])
    source_accounts = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for statement_name, statement in var.publisher_statements : (
        length(trimspace(statement_name)) > 0 &&
        contains(["AWS", "Service"], statement.principals.type) &&
        length(statement.principals.identifiers) > 0
      )
    ])
    error_message = "Each publisher statement must have a non-empty key, a principal type of 'AWS' or 'Service', and at least one principal identifier."
  }

  validation {
    condition = alltrue(flatten([
      for statement_name, statement in var.publisher_statements : [
        for source_account in statement.source_accounts : can(regex("^[0-9]{12}$", source_account))
      ]
    ]))
    error_message = "Each source account in publisher_statements must be a 12-digit AWS account ID."
  }
}

################################################################
# Dead-letter queue
################################################################

variable "dead_letter_queue" {
  description = <<-EOT
    Optional dead-letter queue configuration.

    Defaults:
    - create: false
    - max_receive_count: 5
    - message_retention_seconds: 1209600 (14 days)
    - receive_wait_time_seconds: 20
    - visibility_timeout_seconds: null (inherits primary queue visibility timeout)
  EOT
  type = object({
    create                     = optional(bool, false)
    max_receive_count          = optional(number, 5)
    message_retention_seconds  = optional(number, 1209600)
    receive_wait_time_seconds  = optional(number, 20)
    visibility_timeout_seconds = optional(number)
  })
  default = {}

  validation {
    condition     = var.dead_letter_queue.max_receive_count >= 1 && var.dead_letter_queue.max_receive_count <= 1000
    error_message = "dead_letter_queue.max_receive_count must be between 1 and 1000."
  }

  validation {
    condition     = var.dead_letter_queue.message_retention_seconds >= 60 && var.dead_letter_queue.message_retention_seconds <= 1209600
    error_message = "dead_letter_queue.message_retention_seconds must be between 60 and 1209600."
  }

  validation {
    condition     = var.dead_letter_queue.receive_wait_time_seconds >= 0 && var.dead_letter_queue.receive_wait_time_seconds <= 20
    error_message = "dead_letter_queue.receive_wait_time_seconds must be between 0 and 20."
  }

  validation {
    condition = var.dead_letter_queue.visibility_timeout_seconds == null || (
      var.dead_letter_queue.visibility_timeout_seconds >= 0 &&
      var.dead_letter_queue.visibility_timeout_seconds <= 43200
    )
    error_message = "dead_letter_queue.visibility_timeout_seconds must be null or between 0 and 43200."
  }
}
