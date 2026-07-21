################################################################
# EFS-specific inputs.
################################################################

variable "availability_zone_name" {
  description = "AWS Availability Zone for One Zone storage class. When set, the file system uses single-AZ storage for lower cost. Leave null for multi-AZ."
  type        = string
  default     = null
}

variable "creation_token" {
  description = "A unique name (max 64 chars) used as reference when creating the file system. Enables idempotent creation. When null, Terraform generates a token."
  type        = string
  default     = null
}

variable "custom_name" {
  description = "Optional explicit EFS name. When null, the name is derived from module.this.id."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for encryption at rest. Encryption is mandatory; this variable is required."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:kms:", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid KMS ARN (arn:aws:kms:...)."
  }
}

variable "performance_mode" {
  description = "The file system performance mode. Either 'generalPurpose' or 'maxIO'."
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "performance_mode must be either 'generalPurpose' or 'maxIO'."
  }
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Either 'bursting' (default) or 'provisioned'."
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned"], var.throughput_mode)
    error_message = "throughput_mode must be either 'bursting' or 'provisioned'."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput to provision for the file system in MiB/s. Required when throughput_mode is 'provisioned'. Range: 1–1024."
  type        = number
  default     = null

  validation {
    condition = var.provisioned_throughput_in_mibps == null || (
      var.provisioned_throughput_in_mibps >= 1 && var.provisioned_throughput_in_mibps <= 1024
    )
    error_message = "provisioned_throughput_in_mibps must be between 1 and 1024 MiB/s when set."
  }
}

variable "mount_targets" {
  description = <<-EOT
    Map of mount target configurations. Each mount target must specify:
    - subnet_id: Subnet where the mount target resides (required)
    - security_groups: List of security group IDs (required; caller must enforce ingress rules for NFSv4.1)
    - ip_address: (optional) Static IP address for the mount target
    - ip_address_type: (optional) IP address type (ipv4 or ipv6)
    - ipv6_address: (optional) IPv6 address for the mount target

    Example:
      mount_targets = {
        "az1" = {
          subnet_id       = "subnet-12345"
          security_groups = ["sg-12345"]
        }
        "az2" = {
          subnet_id       = "subnet-67890"
          security_groups = ["sg-67890"]
          ip_address      = "10.0.1.100"
        }
      }
  EOT
  type        = any
  default     = {}

  validation {
    condition = alltrue([
      for mt_key, mt in var.mount_targets : (
        can(mt.subnet_id) &&
        can(mt.security_groups) &&
        length(mt.security_groups) > 0
      )
    ])
    error_message = "Each mount target must have subnet_id and non-empty security_groups list."
  }
}

variable "lifecycle_policy" {
  description = <<-EOT
    Optional lifecycle policy for automatic transition to other storage classes.
    Leave as {} to disable. Example:
      lifecycle_policy = {
        transition_to_ia                  = "AFTER_30_DAYS"
        transition_to_primary_storage_class = "AFTER_1_DAY"
      }
  EOT
  type        = any
  default     = {}
}

variable "protection" {
  description = <<-EOT
    Configuration for replication protection and backup policy.

    Defaults:
    - enable_backup: true (enables automated backups via AWS Backup)
    - replication_overwrite: DISABLED (prevents accidental overwrites of replicas during replication)
  EOT
  type = object({
    enable_backup         = optional(bool, true)
    replication_overwrite = optional(string, "DISABLED")
  })
  default = {}
}

variable "file_system_policy" {
  description = <<-EOT
    Optional IAM policy document (as JSON string) to attach to the file system.
    Controls who can perform what actions on the EFS resource.
    When null, no resource-based policy is attached.

    Security baseline: Callers should consider denying nonsecure (non-TLS) transport:
      - aws:SecureTransport condition set to false
  EOT
  type        = string
  default     = null

  validation {
    condition = var.file_system_policy == null || (
      can(jsondecode(var.file_system_policy)) &&
      can(jsondecode(var.file_system_policy).Statement)
    )
    error_message = "file_system_policy must be a valid JSON IAM policy document."
  }
}

variable "deny_unsecure_transport" {
  description = "Whether to automatically add a Deny statement for non-TLS (unsecure) transport to the file system policy. Recommended: true."
  type        = bool
  default     = true
}

variable "access_points" {
  description = <<-EOT
    Map of EFS Access Point configurations for application-level mount points.
    Access Points enforce POSIX user identities and enforce a file system root.
    Leave as {} to create no access points.

    Example:
      access_points = {
        "app-root" = {
          enforced_user_id = "1000"
          root_directory_path = "/app"
          permissions_mode = "755"
        }
        "db-root" = {
          enforced_user_id = "1001"
          root_directory_path = "/data"
          permissions_mode = "700"
        }
      }
  EOT
  type        = any
  default     = {}

  validation {
    condition = alltrue([
      for ap_key, ap in var.access_points : (
        can(ap.enforced_user_id) &&
        can(ap.root_directory_path) &&
        can(ap.permissions_mode)
      )
    ])
    error_message = "Each access point must have enforced_user_id, root_directory_path, and permissions_mode."
  }
}

variable "replication_configuration" {
  description = <<-EOT
    Replication configuration for cross-region disaster recovery.
    Leave as {} to disable replication.

    Example:
      replication_configuration = {
        destination = "eu-west-1"
      }
  EOT
  type        = any
  default     = {}
}

variable "require_tls_version" {
  description = "Minimum TLS version to enforce via file system policy (e.g., '1.2', '1.3'). When set, a Deny statement is added for lower versions. Leave null to skip TLS version enforcement."
  type        = string
  default     = null

  validation {
    condition     = var.require_tls_version == null || can(regex("^1\\.[2-3]$", var.require_tls_version))
    error_message = "require_tls_version must be null, '1.2', or '1.3'."
  }
}

variable "allowed_source_ips" {
  description = "List of CIDR blocks allowed to access the EFS. When set, a Deny statement restricts access to these IPs. Leave as [] to skip IP-based restrictions."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_source_ips : can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}(/[0-9]{1,2})?$", cidr))
    ])
    error_message = "allowed_source_ips must contain valid CIDR blocks (e.g., '10.0.0.0/8')."
  }
}

variable "deny_destructive_operations" {
  description = "Whether to add a Deny statement for destructive operations (DeleteFileSystem, DeleteAccessPoint) by default. Callers must explicitly allow these via var.file_system_policy. Recommended: true."
  type        = bool
  default     = true
}
