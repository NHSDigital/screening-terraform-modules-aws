################################################################
# Subscription configuration
################################################################

variable "log_group_prefixes" {
  description = "Non-empty list of log-group name prefixes to subscribe as groups are created."
  type        = list(string)

  validation {
    condition     = length(var.log_group_prefixes) > 0 && alltrue([for prefix in var.log_group_prefixes : length(trimspace(prefix)) > 0])
    error_message = "log_group_prefixes must contain at least one non-empty prefix."
  }
}

variable "prefix_filter_patterns" {
  description = "Optional map of log-group prefixes to CloudWatch Logs filter patterns. The longest matching prefix takes precedence."
  type        = map(string)
  default     = {}
}

variable "prefix_exclude_regexes" {
  description = "Optional map of log-group prefixes to regular expressions that exclude matching group names."
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue(flatten([
      for patterns in values(var.prefix_exclude_regexes) : [
        for pattern in patterns : can(regexall(pattern, ""))
      ]
    ]))
    error_message = "Each prefix exclusion must be a valid regular expression."
  }
}

variable "destination_arn" {
  description = "ARN of the same-account Firehose delivery stream."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:firehose:", var.destination_arn))
    error_message = "destination_arn must be a Firehose delivery stream ARN."
  }
}

variable "subscription_role_arn" {
  description = "IAM role ARN that allows CloudWatch Logs to write to the Firehose stream."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+", var.subscription_role_arn))
    error_message = "subscription_role_arn must be an IAM role ARN."
  }
}

variable "filter_pattern" {
  description = "CloudWatch Logs filter pattern for matching newly created groups."
  type        = string
  default     = ""
}

variable "dead_letter_queue_arn" {
  description = "ARN of an SQS queue used as the EventBridge target dead-letter queue."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:sqs:", var.dead_letter_queue_arn))
    error_message = "dead_letter_queue_arn must be an SQS queue ARN."
  }
}

variable "python_version" {
  description = "Python runtime used by the subscription controller Lambda."
  type        = string
  default     = "python3.12"
}

variable "log_retention_days" {
  description = "Retention period for the controller Lambda log group."
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "Optional KMS key ARN for the controller Lambda log group."
  type        = string
  default     = null
}
