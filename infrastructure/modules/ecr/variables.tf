######################
# Generic
######################
variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

variable "repo_name" {
  description = "The name of the ECR repository"
  type        = string
}

variable "developer_sso_role" {
  description = "The SSO role for developers"
  type        = string
}


variable "lifecycle_rules" {
  description = <<EOT
List of lifecycle rules. Each rule must be an object:
{
  priority    = number
  description = string
  selection = {
    tag_status       = string
    tag_prefix_list  = optional(list(string))
    tag_pattern_list = optional(list(string))
    count_type       = string
    count_number     = number
    count_unit       = optional(string)
  }
}
EOT
  type = list(object({
    priority    = number
    description = string
    selection = object({
      tag_status       = string
      tag_prefix_list  = optional(list(string))
      tag_pattern_list = optional(list(string))
      count_type       = string
      count_number     = number
      count_unit       = optional(string)
    })
  }))
  default = []
}
