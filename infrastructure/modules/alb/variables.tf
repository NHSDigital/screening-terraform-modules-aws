################################################################
# ALB/NLB-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
#
# Inputs intentionally NOT exposed (hardcoded in main.tf):
#   - enable_deletion_protection → always true
#   - drop_invalid_header_fields → always true for ALB
################################################################

variable "load_balancer_type" {
  type        = string
  default     = "application"
  description = "Type of load balancer to create. Either 'application' (ALB) or 'network' (NLB)."

  validation {
    condition     = contains(["application", "network"], var.load_balancer_type)
    error_message = "load_balancer_type must be 'application' or 'network'."
  }
}

variable "internal" {
  type        = bool
  default     = false
  description = "When true, the load balancer is internal (private). When false, it is internet-facing. Defaults to false."
}

variable "subnets" {
  type        = list(string)
  description = "List of subnet IDs to attach to the load balancer. For internet-facing ALBs, use public subnets."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which the load balancer security group will be created."
}

variable "security_group_ingress_rules" {
  type        = any
  default     = {}
  description = <<-EOT
    Map of ingress rules to add to the load balancer security group.
    Each key is a logical name; each value is an object describing the rule.
    Example:
      security_group_ingress_rules = {
        https = {
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          description = "HTTPS from internet"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
  EOT
}

variable "security_group_egress_rules" {
  type        = any
  default     = {}
  description = <<-EOT
    Map of egress rules to add to the load balancer security group.
    Example:
      security_group_egress_rules = {
        https_out = {
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
  EOT
}

variable "access_logs" {
  type = object({
    bucket  = string
    prefix  = optional(string)
    enabled = optional(bool, true)
  })
  default     = null
  description = "S3 access log delivery configuration. When null, access logging is disabled."
}

variable "listeners" {
  type        = any
  default     = {}
  description = <<-EOT
    Map of listener configurations to create. Passed directly to the upstream module.
    For ALB, define HTTPS and HTTP listeners here. For NLB, define TCP/TLS listeners.
    See https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest
    for full schema documentation.
  EOT
}

variable "target_groups" {
  type        = any
  default     = {}
  description = <<-EOT
    Map of target group configurations to create. Passed directly to the upstream module.
    See https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest
    for full schema documentation.
  EOT
}

variable "web_acl_arn" {
  type        = string
  default     = null
  description = "ARN of a WAFv2 Web ACL to associate with the load balancer. Only valid for ALB. When null, no WAF association is created."
}

variable "enable_deletion_protection" {
  type        = bool
  default     = true
  description = "When true, deletion protection is enabled on the load balancer. Set to false for non-production environments where the load balancer needs to be freely destroyed."
}

variable "enable_http_https_redirect" {
  type        = bool
  default     = true
  description = "When true, automatically adds a port-80 HTTP-to-HTTPS (301) redirect listener. Only applies when load_balancer_type is 'application'. Set to false if you are defining your own HTTP listener or the ALB is not serving HTTPS traffic."
}
