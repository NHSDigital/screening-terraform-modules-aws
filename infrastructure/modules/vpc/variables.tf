################################################################
# VPC-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# `context.tf` via `module.this`.
################################################################

variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC. Must be a /16 for the default subnet auto-calculation to work."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

################################################################
# Subnet CIDR overrides
#
# When left empty (default) the module auto-calculates CIDRs
# from var.vpc_cidr
################################################################

variable "firewall_subnets" {
  description = "Explicit /28 CIDR blocks for firewall subnets (one per AZ). Leave empty to auto-calculate."
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "Explicit /24 CIDR blocks for public subnets (one per AZ). Leave empty to auto-calculate."
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "Explicit /23 CIDR blocks for private subnets with NAT (one per AZ). Leave empty to auto-calculate."
  type        = list(string)
  default     = []
}

variable "isolated_subnets" {
  description = "Explicit /23 CIDR blocks for fully isolated subnets with no internet route (one per AZ). Leave empty to auto-calculate."
  type        = list(string)
  default     = []
}

################################################################
# NAT Gateway
################################################################

variable "single_nat_gateway" {
  description = "Provision a single shared NAT Gateway instead of one per AZ. Saves cost but reduces availability."
  type        = bool
  default     = false
}

################################################################
# DNS
################################################################

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

################################################################
# Public subnets
################################################################

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs to instances launched in public subnets."
  type        = bool
  default     = false
}

################################################################
# Security defaults
################################################################

variable "manage_default_security_group" {
  description = "Adopt and manage the default security group, removing all inline rules."
  type        = bool
  default     = true
}

variable "manage_default_network_acl" {
  description = "Adopt and manage the default network ACL."
  type        = bool
  default     = true
}

################################################################
# Subnet tags
################################################################

variable "public_subnet_tags" {
  description = "Additional tags for the public subnets."
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for the private (NAT-routed) subnets."
  type        = map(string)
  default     = {}
}

variable "isolated_subnet_tags" {
  description = "Additional tags for the isolated (no-internet) subnets."
  type        = map(string)
  default     = {}
}

variable "firewall_subnet_tags" {
  description = "Additional tags for the firewall subnets."
  type        = map(string)
  default     = {}
}

################################################################
# VPC Flow Logs
################################################################

variable "enable_flow_log" {
  description = "Enable VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_in_days" {
  description = "Number of days to retain VPC flow logs in CloudWatch."
  type        = number
  default     = 365
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be one of ACCEPT, REJECT, ALL."
  }
}

variable "flow_log_kms_key_id" {
  description = "ARN of a KMS key to encrypt the CloudWatch log group. Leave null for no encryption."
  type        = string
  default     = null
}
