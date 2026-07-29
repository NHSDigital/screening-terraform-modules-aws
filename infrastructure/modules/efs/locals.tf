################################################################
# Local values
#
# EFS name is derived from the context, with optional override.
# File system policy is built with optional security statements.
################################################################

locals {
  # Naming logic - derive from context, allow caller override
  efs_name = var.custom_name != null ? var.custom_name : module.this.id

  # Scope default statements to this file system only.
  file_system_arn = module.efs.arn
}

data "aws_iam_policy_document" "deny_unsecure_transport" {
  count = module.this.enabled && var.deny_unsecure_transport ? 1 : 0

  statement {
    sid       = "DenyUnsecureTransport"
    effect    = "Deny"
    actions   = ["elasticfilesystem:*"]
    resources = [local.file_system_arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AccessedViaMountTarget"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientMount"
    ]
    resources = [local.file_system_arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy_document" "require_tls_version" {
  count = module.this.enabled && var.require_tls_version != null ? 1 : 0

  statement {
    sid       = "DenyOldTLSVersion"
    effect    = "Deny"
    actions   = ["elasticfilesystem:*"]
    resources = [local.file_system_arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringLessThan"
      variable = "aws:TlsVersion"
      values   = [var.require_tls_version]
    }
  }
}

data "aws_iam_policy_document" "deny_destructive_operations" {
  count = module.this.enabled && var.deny_destructive_operations ? 1 : 0

  statement {
    sid    = "DenyDestructiveOperations"
    effect = "Deny"
    actions = [
      "elasticfilesystem:DeleteFileSystem",
      "elasticfilesystem:DeleteAccessPoint",
      "elasticfilesystem:DeleteMountTarget",
      "elasticfilesystem:DeleteReplicationConfiguration"
    ]
    resources = [local.file_system_arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

locals {
  # Build list of default security statements to add to the policy
  default_policy_statement = concat(
    try(jsondecode(data.aws_iam_policy_document.deny_unsecure_transport[0].json).Statement, []),
    try(jsondecode(data.aws_iam_policy_document.require_tls_version[0].json).Statement, []),
    try(jsondecode(data.aws_iam_policy_document.deny_destructive_operations[0].json).Statement, [])
  )

  # File system policy: merge caller policy with default security statements
  file_system_policy_doc = length(local.default_policy_statement) > 0 || var.file_system_policy != null ? jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.file_system_policy != null ? jsondecode(var.file_system_policy).Statement : [],
      local.default_policy_statement
    )
  }) : null
}
