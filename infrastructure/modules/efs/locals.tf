################################################################
# Local values
#
# EFS name is derived from the context, with optional override.
# File system policy is built with optional security statements.
################################################################

locals {
  # Naming logic — derive from context, allow caller override
  efs_name = var.custom_name != null ? var.custom_name : module.this.id

  # Build list of default security statements to add to the policy
  default_policy_statements = concat(
    # Deny unsecure (non-TLS) transport
    var.deny_unsecure_transport ? [
      {
        Sid       = "DenyUnsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "elasticfilesystem:*"
        Resource  = "*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ] : [],

    # Deny old TLS versions (require TLS 1.2+)
    var.require_tls_version != null ? [
      {
        Sid       = "DenyOldTLSVersion"
        Effect    = "Deny"
        Principal = "*"
        Action    = "elasticfilesystem:*"
        Resource  = "*"
        Condition = {
          StringLessThan = {
            "aws:TlsVersion" = var.require_tls_version
          }
        }
      }
    ] : [],

    # Deny access from IPs outside allowed list
    length(var.allowed_source_ips) > 0 ? [
      {
        Sid       = "DenyUnauthorizedSourceIPs"
        Effect    = "Deny"
        Principal = "*"
        Action    = "elasticfilesystem:*"
        Resource  = "*"
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = var.allowed_source_ips
          }
        }
      }
    ] : [],

    # Deny destructive operations by default
    var.deny_destructive_operations ? [
      {
        Sid       = "DenyDestructiveOperations"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "elasticfilesystem:DeleteFileSystem",
          "elasticfilesystem:DeleteAccessPoint",
          "elasticfilesystem:DeleteMountTarget",
          "elasticfilesystem:DeleteReplicationConfiguration"
        ]
        Resource = "*"
      }
    ] : []
  )

  # File system policy: merge caller policy with default security statements
  file_system_policy_doc = length(local.default_policy_statements) > 0 || var.file_system_policy != null ? jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.file_system_policy != null ? jsondecode(var.file_system_policy).Statement : [],
      local.default_policy_statements
    )
  }) : null
}
