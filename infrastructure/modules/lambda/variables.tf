variable "function_name" {
  description = "Optional explicit name for the Lambda function. When null, the module uses module.this.id from context.tf."
  type        = string
  default     = null

  validation {
    condition     = var.function_name == null || length(trimspace(var.function_name)) > 0
    error_message = "function_name must be null or a non-empty string when specified."
  }
}

variable "python_version" {
  description = "The Python version to use for the Lambda function"
  type        = string
}

variable "handler_prefix" {
  description = "The prefix for the Lambda handler function"
  type        = string
}

variable "handler" {
  description = "Optional fully qualified Lambda handler. When null, the module uses <handler_prefix>.lambda_handler."
  type        = string
  default     = null
}

variable "function_description" {
  description = "The description for the Lambda function"
  type        = string
}

variable "environment_variables" {
  description = "Values to set in the Lambda function environment"
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = "List of Lambda Layer ARNs to attach to the function"
  type        = list(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "List of VPC subnet IDs for the Lambda function"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs for the Lambda function"
  type        = list(string)
  default     = []
}

variable "timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 120
}

variable "attach_default_policies" {
  description = "Whether to attach the four legacy AWS-managed execution policies. Disable this when supplying a least-privilege execution_policy_json."
  type        = bool
  default     = true
}

variable "attach_cloudwatch_logs_policy" {
  description = "Whether the upstream Lambda module attaches its default CloudWatch Logs policy. Disable this when log permissions are included in execution_policy_json."
  type        = bool
  default     = true
}

variable "execution_policy_json" {
  description = "Optional JSON IAM policy document attached inline to the Lambda execution role."
  type        = string
  default     = null

  validation {
    condition     = var.execution_policy_json == null || can(jsondecode(var.execution_policy_json))
    error_message = "execution_policy_json must be valid JSON when specified."
  }
}

variable "source_path" {
  description = <<-EOT
    Optional override for the directory containing the Lambda's source code.
    Resolved relative to the root module (the stack) at plan/apply time.

    When null (default), the module falls back to the historical layout
    `../../lambdas/<handler_prefix>/`, which expects sources under a top-level
    `infrastructure_v2/lambdas/` directory.

    Set this to keep a stack's Lambda source co-located with the stack,
    e.g. source_path = "lambdas/slack-notifier".
  EOT
  type        = string
  default     = null
}
