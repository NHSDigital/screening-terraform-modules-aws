variable "topic_name" {
  description = "SNS topic name override. If null, the module derives a name from context (`module.this.id`)."
  type        = string
  default     = null
}

variable "aws_account_id" {
  sensitive   = true
  description = "The AWS account ID. Retained for compatibility with legacy callers and policy conditions."
  type        = string
}

variable "ecs_role_prefix" {
  description = "IAM role name prefix used in the ECS publish policy condition. Defaults to the topic name (matching legacy `name_prefix` behaviour). Set this explicitly if your ECS task roles use a different prefix than the topic name."
  type        = string
  default     = null
}

variable "subscriptions" {
  description = "Map of SNS subscriptions to create (passed through to terraform-aws-modules/sns/aws)."
  type = map(object({
    confirmation_timeout_in_minutes = optional(number)
    delivery_policy                 = optional(string)
    endpoint                        = string
    endpoint_auto_confirms          = optional(bool)
    filter_policy                   = optional(string)
    filter_policy_scope             = optional(string)
    protocol                        = string
    raw_message_delivery            = optional(bool)
    redrive_policy                  = optional(string)
    replay_policy                   = optional(string)
    subscription_role_arn           = optional(string)
  }))
  default = {}
}
