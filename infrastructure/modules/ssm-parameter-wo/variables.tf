################################################################
# Parameter definition
################################################################

variable "type" {
  description = "Type of the parameter. Valid types are `String`, `StringList` and `SecureString`"
  type        = string

  validation {
    condition     = contains(["String", "StringList", "SecureString"], var.type)
    error_message = "`type` must be either \"String\", \"StringList\", or \"SecureString\""
  }
}

variable "parameter_name" {
  description = "Optional override for the full SSM parameter name (e.g., `/bcss/prod/myapp/config`). When provided, this takes precedence over the context-derived name. If not specified, the parameter name is derived from context as `/<service>/<project>/<environment>/<stack>/<name>`."
  type        = string
  default     = null

  validation {
    condition     = var.parameter_name == null || can(regex("^/", coalesce(var.parameter_name, "/")))
    error_message = "parameter_name must start with a forward slash, e.g. \"/bcss/prod/myapp/config\"."
  }
}

variable "description" {
  description = "Description of the parameter"
  type        = string
  default     = null
}

variable "tier" {
  description = "Parameter tier to assign to the parameter. If not specified, will use the default parameter tier for the region. Valid tiers are Standard, Advanced, and Intelligent-Tiering. Downgrading an Advanced tier parameter to Standard will recreate the resource"
  type        = string
  default     = null
}

variable "ssm_data_type" {
  description = "Data type of the parameter. Valid values: `text`, `aws:ssm:integration` and `aws:ec2:image` for AMI format, see https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-ec2-aliases.html"
  type        = string
  default     = null
}

variable "allowed_pattern" {
  description = "Regular expression used to validate the parameter value"
  type        = string
  default     = null
}

variable "overwrite" {
  description = "Overwrite an existing parameter. If not specified, defaults to `false` during create operations to avoid overwriting existing resources and then `true` for all subsequent operations once the resource is managed by Terraform"
  type        = bool
  default     = null
}

variable "ignore_value_changes" {
  description = "Whether to create the SSM parameter and then ignore changes to its value, e.g. when the value is managed in the console or by rotation automation"
  type        = bool
  default     = false
}

################################################################
# Encryption
################################################################

variable "key_id" {
  description = "KMS key ID or ARN for encrypting a `SecureString`"
  type        = string
  default     = null

  validation {
    condition     = !module.this.enabled || var.type != "SecureString" || var.key_id != null
    error_message = "`key_id` must be specified when `type` is \"SecureString\""
  }
}

################################################################
# Values
#
# Cross-variable rules live in variable validations rather than
# validations.tf: they must fail before the provider's own
# argument checks on aws_ssm_parameter, which preconditions do not.
################################################################

variable "value" {
  description = "Value of the parameter. For `String`/`StringList` it is stored in state as `insecure_value`. For `SecureString` it is sent via the write-only `value_wo` argument and never stored; prefer `value_wo` so ephemeral values can be used."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = !module.this.enabled || var.type == "SecureString" || var.value != null || length(var.values) > 0
    error_message = "String and StringList require value or values."
  }

  validation {
    condition     = !(var.value != null && length(var.values) > 0)
    error_message = "value and values are mutually exclusive; specify only one."
  }
}

variable "values" {
  description = "List of values for a `StringList` parameter (JSON-encoded before being stored)."
  type        = list(string)
  default     = []
  sensitive   = true

  validation {
    condition     = length(var.values) == 0 || var.type == "StringList"
    error_message = "values is only valid when type is \"StringList\"."
  }
}

variable "value_wo" {
  description = "Write-only value for a `SecureString` parameter. Accepts ephemeral values and is never stored in state or plan files. Requires `value_wo_version`."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true

  validation {
    condition     = var.value_wo == null || var.type == "SecureString"
    error_message = "value_wo is only valid when type is \"SecureString\"."
  }

  validation {
    condition     = !(var.value != null && var.value_wo != null)
    error_message = "value and value_wo are mutually exclusive; specify only one."
  }

  validation {
    condition     = !module.this.enabled || var.type != "SecureString" || var.value != null || var.value_wo != null
    error_message = "SecureString requires value_wo (preferred) or value."
  }
}

variable "value_wo_version" {
  description = "Version trigger for the write-only SecureString value. Required for `SecureString`; Terraform only re-sends the value when this number changes."
  type        = number
  default     = null

  validation {
    condition     = !module.this.enabled || var.type != "SecureString" || var.value_wo_version != null
    error_message = "`value_wo_version` must be specified when `type` is \"SecureString\""
  }

  validation {
    condition     = var.value_wo_version == null || var.type == "SecureString"
    error_message = "value_wo_version is only valid when type is \"SecureString\"."
  }
}
