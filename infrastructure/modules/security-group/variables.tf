################################################################
# Security group-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "description" {
  description = "Description for the security group"
  type        = string
  default     = null
}

variable "enable_exclusive_rules" {
  description = "Whether to enforce that only the rules declared by this module exist on the security group. When true, out-of-band rules added via the AWS console or other Terraform configurations will be reverted on next apply"
  type        = bool
  default     = true
}
variable "egress_rules" {
  description = "Map of egress rules to add to the security group"
  type = map(object({
    name                         = optional(string)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    from_port                    = optional(number)
    ip_protocol                  = optional(string, "tcp")
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  }))
  default = {}
}

variable "ingress_rules" {
  description = "Map of ingress rules to add to the security group"
  type = map(object({
    name                         = optional(string)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    from_port                    = optional(number)
    ip_protocol                  = optional(string, "tcp")
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  }))
  default = {}
}

variable "revoke_rules_on_delete" {
  description = "Whether to revoke all rules on the security group when it is deleted. This is useful for security groups that are shared across multiple resources, as it prevents orphaned rules from remaining after the security group is deleted."
  type        = bool
  default     = false
}

variable "security_group_name" {
  description = "Name of security group"
  type        = string
  default     = ""
}

variable "use_name_prefix" {
  description = "Whether to use the name (`name`) as a prefix, appending a random suffix"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC where the security group is created; defaults to the region's default VPC"
  type        = string
  default     = null
}
