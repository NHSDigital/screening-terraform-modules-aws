################################################################
# VPC Configuration
################################################################

variable "vpc_id" {
  description = "The ID of the VPC where endpoints will be created."
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{17}$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC ID (vpc-xxxxxxxxxxxxxxxx)."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs to use as default for Interface endpoints (recommended: intra subnets with no internet route). Can be overridden per-endpoint via subnet_ids in the endpoints map."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet ID."
  }
}

variable "security_group_id" {
  description = "Default security group ID to associate with Interface endpoints. Per-endpoint security_group_ids override this default. Can be null if all Interface endpoints specify security_group_ids explicitly."
  type        = string
  default     = null

  validation {
    condition     = var.security_group_id == null || can(regex("^sg-[a-f0-9]{17}$", var.security_group_id))
    error_message = "security_group_id must be a valid AWS security group ID (sg-xxxxxxxxxxxxxxxx) or null."
  }
}

################################################################
# VPC Endpoints Configuration
################################################################

variable "endpoints" {
  description = <<-EOT
    Map of VPC endpoints to create. Each key is a logical name,
    each value is passed through to the upstream vpc-endpoints submodule.

    **Interface endpoints** (default):
      - Placed in intra subnets by default (can override via subnet_ids)
      - Require security_group_ids
      - Support optional private_dns_enabled (default true)

    **Gateway endpoints**:
      - Must specify service_type = "Gateway"
      - Require route_table_ids
      - Do NOT use security_group_ids or subnet_ids

    Supported per-endpoint attributes:
      service              - AWS service name (e.g. "s3", "ecr.api") [REQUIRED]
      service_type         - "Interface" (default) or "Gateway"
      policy               - JSON endpoint policy document (optional but recommended)
      subnet_ids           - Override default intra subnets (optional; Interface only)
      security_group_ids   - Security group IDs (required for Interface endpoints)
      private_dns_enabled  - Enable private DNS (Interface only; default true)
      route_table_ids      - Route table IDs (required for Gateway endpoints)
      tags                 - Per-endpoint tags (optional)

    **Security consideration:** Endpoint policies restrict access. If not specified,
    the endpoint allows all principals. Recommended to set restrictive policies.
  EOT
  type        = any
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.endpoints : try(v.service, null) != null])
    error_message = "Each endpoint must specify 'service' (e.g. 's3', 'ecr.api')."
  }

  validation {
    condition = alltrue([
      for k, v in var.endpoints :
      try(v.service_type, "Interface") != "Interface" || var.security_group_id != null || (try(v.security_group_ids, null) != null && length(try(v.security_group_ids, [])) > 0)
    ])
    error_message = "Interface endpoints must have security groups via either var.security_group_id (default) or per-endpoint security_group_ids."
  }

  validation {
    condition = alltrue([
      for k, v in var.endpoints :
      try(v.service_type, "Interface") == "Gateway" ?
      try(v.route_table_ids, null) != null && length(try(v.route_table_ids, [])) > 0 :
      true
    ])
    error_message = "Gateway endpoints must specify route_table_ids with at least one route table."
  }
}
