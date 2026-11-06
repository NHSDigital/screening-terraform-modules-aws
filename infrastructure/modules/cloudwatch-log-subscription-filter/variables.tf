################################################################
# Subscription filter
################################################################

variable "log_group_name" {
  description = "Name of an existing CloudWatch log group to subscribe."
  type        = string

  validation {
    condition     = length(trimspace(var.log_group_name)) > 0
    error_message = "log_group_name must not be empty."
  }
}

variable "destination_arn" {
  description = "ARN of the same-account Firehose delivery stream or other supported subscription destination."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:(firehose|kinesis|lambda):", var.destination_arn))
    error_message = "destination_arn must be an ARN for a supported CloudWatch Logs subscription destination."
  }
}

variable "role_arn" {
  description = "ARN of the IAM role that allows CloudWatch Logs to deliver events to the destination."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+", var.role_arn))
    error_message = "role_arn must be an IAM role ARN."
  }
}

variable "filter_pattern" {
  description = "CloudWatch Logs filter pattern. An empty string matches all log events."
  type        = string
  default     = ""
}

variable "distribution" {
  description = "Distribution method supported by the selected destination."
  type        = string
  default     = null

  validation {
    condition     = var.distribution == null || contains(["Random", "ByLogStream"], var.distribution)
    error_message = "distribution must be Random, ByLogStream, or null."
  }
}
