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

variable "vpc_id" {
  description = "ID of the VPC where the security group is created; defaults to the region's default VPC"
  type        = string
  default     = null
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
