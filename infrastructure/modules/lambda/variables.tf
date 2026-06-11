variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
  default     = "uk-forwarder"
}

variable "python_version" {
  description = "The Python version to use for the Lambda function"
  type        = string
}

variable "handler_prefix" {
  description = "The prefix for the Lambda handler function"
  type        = string
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
