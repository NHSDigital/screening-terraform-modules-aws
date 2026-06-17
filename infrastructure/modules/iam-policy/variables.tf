variable "description" {
  description = "The description of the policy"
  type        = string
  default     = null
}

variable "path" {
  description = "The path of the policy"
  type        = string
  default     = "/"
}

variable "policy" {
  description = "Policy document. This is a JSON formatted string."
  type        = string
  default     = null
}
