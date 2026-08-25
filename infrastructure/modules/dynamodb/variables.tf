################################################################
# DynamoDB-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "table_name" {
  description = "Optional explicit table name. When null, the table is named from `module.this.id`."
  type        = string
  default     = null
}

variable "hash_key" {
  description = "Attribute name to use as the partition (hash) key. Must be present in `var.attributes`."
  type        = string
}

variable "range_key" {
  description = "Attribute name to use as the sort (range) key. Must be present in `var.attributes` when set."
  type        = string
  default     = null
}

variable "table_attributes" {
  description = "List of attribute definitions. Each entry must have `name` (string) and `type` (S, N, or B). Must include entries for `hash_key` and `range_key`."
  type = list(object({
    name = string
    type = string
  }))
}

variable "billing_mode" {
  description = "Controls how you are billed for read/write throughput. Valid values are `PROVISIONED` or `PAY_PER_REQUEST`."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "billing_mode must be one of: PROVISIONED, PAY_PER_REQUEST."
  }
}

variable "read_capacity" {
  description = "Read capacity units. Required when `billing_mode` is `PROVISIONED`; ignored for `PAY_PER_REQUEST`."
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "Write capacity units. Required when `billing_mode` is `PROVISIONED`; ignored for `PAY_PER_REQUEST`."
  type        = number
  default     = null
}

variable "kms_key_arn" {
  description = "Optional ARN of a customer-managed KMS key. When set, encryption switches from AWS-managed (alias/aws/dynamodb) to CMK. Source this from the `kms` module."
  type        = string
  default     = null
}

variable "global_secondary_indexes" {
  description = "List of global secondary index definitions."
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = string
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  default = []
}

variable "local_secondary_indexes" {
  description = "List of local secondary index definitions. These can only be set at table creation time."
  type = list(object({
    name               = string
    range_key          = string
    projection_type    = string
    non_key_attributes = optional(list(string))
  }))
  default = []
}

variable "ttl_attribute_name" {
  description = "Name of the attribute used to store the TTL expiry timestamp."
  type        = string
  default     = null
}

variable "ttl_enabled" {
  description = "Whether TTL is enabled on the table."
  type        = bool
  default     = false
}

variable "stream_enabled" {
  description = "Whether DynamoDB Streams are enabled on the table."
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Determines what information is written to the stream when an item is modified. Valid values: `KEYS_ONLY`, `NEW_IMAGE`, `OLD_IMAGE`, `NEW_AND_OLD_IMAGES`. Required when `stream_enabled` is true."
  type        = string
  default     = null

  validation {
    condition     = var.stream_view_type == null || contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], var.stream_view_type)
    error_message = "stream_view_type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  }
}
