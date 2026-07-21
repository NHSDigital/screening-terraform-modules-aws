################################################################
# ALB/NLB-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
#
# Inputs intentionally NOT exposed (hardcoded in main.tf):
#   - create_security_group → always false (use var.security_groups)
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
  description = "ID of the VPC in which the load balancer will be created."
}

variable "security_groups" {
  type        = list(string)
  description = <<-EOT
    List of security group IDs to attach to the load balancer.
    REQUIRED — callers must pre-create security groups with appropriate ingress/egress rules.
    This enforces explicit security group management and prevents accidental exposure.
    Example:
      security_groups = [aws_security_group.alb.id]
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

variable "desync_mitigation_mode" {
  type        = string
  default     = "defensive"
  description = "HTTP request desync mitigation mode. Valid values: 'off', 'defensive', 'strictest', 'monitor'. Only valid for ALB. 'defensive' is the AWS default and recommended for security. See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#desync-mitigation-mode"

  validation {
    condition     = contains(["off", "defensive", "strictest", "monitor"], var.desync_mitigation_mode)
    error_message = "desync_mitigation_mode must be one of: off, defensive, strictest, monitor."
  }
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "Time in seconds that a connection is allowed to be idle. Valid range: 1–4000. Defaults to 60. Apply to both ALB and NLB."

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "idle_timeout must be between 1 and 4000."
  }
}

variable "preserve_host_header" {
  type        = bool
  default     = false
  description = "When true, ALB preserves the original Host header from the client request instead of rewriting it. Only valid for ALB. Defaults to false."
}

variable "xff_header_processing_mode" {
  type        = string
  default     = "append"
  description = "How the ALB handles X-Forwarded-For headers. Valid values: 'append', 'replace', 'remove'. 'append' is AWS default. Only valid for ALB."

  validation {
    condition     = contains(["append", "replace", "remove"], var.xff_header_processing_mode)
    error_message = "xff_header_processing_mode must be one of: append, replace, remove."
  }
}

variable "enable_http2" {
  type        = bool
  default     = true
  description = "When true, HTTP/2 is enabled on the ALB. Improves connection efficiency. Only valid for ALB. Defaults to true."
}

variable "enable_cross_zone_load_balancing" {
  type        = bool
  default     = true
  description = "When true, cross-zone load balancing distributes traffic across all registered targets in all enabled AZs. Defaults to true. Incurs additional data transfer costs but provides better availability."
}
