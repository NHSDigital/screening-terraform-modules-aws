################################################################
# VPC-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# `context.tf` via `module.this`.
################################################################
variable "enable_network_firewall" {
  description = <<-EOT
    When true, the VPC module creates firewall subnets, takes over
    IGW management from the community module, and reconfigures
    routing for AWS Network Firewall inspection:
      - Firewall subnets created as standalone resources
      - IGW created as a standalone resource (community module's create_igw = false)
      - Firewall subnets get a default route (0.0.0.0/0) to the IGW
      - Public subnet default route is NOT created (callers must
        inject 0.0.0.0/0 → firewall VPCE at the stack level)
    When false (default), no firewall subnets are created, the
    community module creates the IGW and public → IGW route as
    normal — no Network Firewall in the path.
  EOT
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC (AWS allows /16 to /28 netmask). Subnet CIDR blocks are auto-calculated from this VPC CIDR using the *_subnet_prefix variables."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }

  validation {
    condition = (
      can(tonumber(split("/", var.vpc_cidr)[1])) &&
      tonumber(split("/", var.vpc_cidr)[1]) >= 16 &&
      tonumber(split("/", var.vpc_cidr)[1]) <= 28
    )
    error_message = "VPC CIDR prefix must be between /16 (65,536 IPs) and /28 (16 IPs) per AWS limits. Whilst technically /28 is allowed, it is too small to support the module's multiple subnets and AWS reserved IPs."
  }
}

################################################################
# Subnet prefix lengths
#
# Control the size of each subnet tier.  The module uses
# cidrsubnets() to carve non-overlapping ranges automatically.
################################################################

variable "availability_zones" {
  description = "Availability zones to use for the VPC. Leave null to use the first three available AZs in the current region."
  type        = list(string)
  default     = null
}

################################################################
# Subnet type creation flags
#
# Control which subnet tiers are created.  When a subnet type
# is disabled, its prefix and CIDR calculations are skipped.
################################################################

variable "create_firewall_subnets" {
  description = "Whether to create firewall subnets (required for Network Firewall routing mode)."
  type        = bool
  default     = true
}

variable "create_public_subnets" {
  description = "Whether to create public subnets (internet-facing resources, NAT gateways)."
  type        = bool
  default     = true
}

variable "create_private_subnets" {
  description = "Whether to create private subnets (workloads with outbound internet access via NAT gateway)."
  type        = bool
  default     = true
}

variable "create_intra_subnets" {
  description = "Whether to create intra subnets (no internet access)."
  type        = bool
  default     = true
}

variable "firewall_subnet_prefix" {
  description = "Prefix length for firewall subnets (e.g. 28 = /28, 16 IPs each). AWS allows /16 to /28. Must be more specific (larger numerically) than vpc_cidr when auto-calculating. Used only when firewall_subnets list is empty; when explicit firewall_subnets are provided, this value is ignored. Highly recommended: /28 to minimize wasted IPs."
  type        = number
  default     = 28

  validation {
    condition     = var.firewall_subnet_prefix >= 16 && var.firewall_subnet_prefix <= 28
    error_message = "firewall_subnet_prefix must be between /16 and /28 per AWS limits."
  }
}

variable "public_subnet_prefix" {
  description = "Prefix length for public subnets (e.g. 24 = /24, 256 IPs each). AWS allows /16 to /28. Must be more specific (larger numerically) than vpc_cidr when auto-calculating. Used only when public_subnets list is empty; when explicit public_subnets are provided, this value is ignored."
  type        = number
  default     = 24

  validation {
    condition     = var.public_subnet_prefix >= 16 && var.public_subnet_prefix <= 28
    error_message = "public_subnet_prefix must be between /16 and /28 per AWS limits."
  }
}

variable "private_subnet_prefix" {
  description = "Prefix length for private subnets with NAT (e.g. 23 = /23, 512 IPs each). AWS allows /16 to /28. Must be more specific (larger numerically) than vpc_cidr when auto-calculating. Used only when private_subnets list is empty; when explicit private_subnets are provided, this value is ignored."
  type        = number
  default     = 23

  validation {
    condition     = var.private_subnet_prefix >= 16 && var.private_subnet_prefix <= 28
    error_message = "private_subnet_prefix must be between /16 and /28 per AWS limits."
  }
}

variable "intra_subnet_prefix" {
  description = "Prefix length for intra subnets with no internet route (e.g. 23 = /23, 512 IPs each). AWS allows /16 to /28. Must be more specific (larger numerically) than vpc_cidr when auto-calculating. Used only when intra_subnets list is empty; when explicit intra_subnets are provided, this value is ignored."
  type        = number
  default     = 23

  validation {
    condition     = var.intra_subnet_prefix >= 16 && var.intra_subnet_prefix <= 28
    error_message = "intra_subnet_prefix must be between /16 and /28 per AWS limits."
  }
}

################################################################
# Subnet CIDR overrides
#
# When left empty (default) the module auto-calculates CIDRs
# from var.vpc_cidr using the prefix lengths above.
################################################################

variable "firewall_subnets" {
  description = "Explicit CIDR blocks for firewall subnets (one per AZ). Leave empty to auto-calculate."
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "Explicit CIDR blocks for public subnets (one per AZ). Leave empty to auto-calculate."
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "Explicit CIDR blocks for private subnets with NAT (one per AZ). Leave empty to auto-calculate."
  type        = list(string)
  default     = []
}

variable "intra_subnets" {
  description = "Explicit CIDR blocks for intra subnets with no internet route (one per AZ). Leave empty to auto-calculate."
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
# DHCP Options
################################################################

variable "enable_dhcp_options" {
  description = "Create a custom DHCP option set and associate it with the VPC."
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "The suffix domain name to use by default when resolving non-FQDNs."
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "List of DNS server addresses for the DHCP option set. Use ['AmazonProvidedDNS'] for the default VPC resolver, or Route 53 Resolver inbound endpoint IPs."
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "List of NTP servers for the DHCP option set."
  type        = list(string)
  default     = []
}

variable "dhcp_options_tags" {
  description = "Additional tags for the DHCP option set."
  type        = map(string)
  default     = {}
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

variable "intra_subnet_tags" {
  description = "Additional tags for the intra (no-internet) subnets."
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

variable "flow_log_max_aggregation_interval" {
  description = "The maximum interval of time (seconds) during which a flow of packets is captured. Valid values: 60 (1 min) or 600 (10 min)."
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.flow_log_max_aggregation_interval)
    error_message = "flow_log_max_aggregation_interval must be 60 or 600."
  }
}

variable "cloudwatch_log_group_tags" {
  description = "Additional tags for the CloudWatch log group."
  type        = map(string)
  default     = {}
}

variable "flow_log_tags" {
  description = "Additional tags for the VPC flow log."
  type        = map(string)
  default     = {}
}

variable "iam_role_tags" {
  description = "Additional tags for the IAM role used by the VPC flow log."
  type        = map(string)
  default     = {}
}

################################################################
# VPC Endpoints
