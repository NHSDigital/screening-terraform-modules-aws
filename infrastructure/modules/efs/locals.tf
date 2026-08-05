################################################################
# Local values
#
# EFS name is derived from the context, with optional override.
# File system policy is built with optional security statements.
################################################################

locals {
  # Naming logic - derive from context, allow caller override
  efs_name = var.custom_name != null ? var.custom_name : module.this.id

  # Use "*" because the resource-based policy is already scoped to the
  # specific file system via file_system_id. Using module.efs.arn would
  # be unknown at plan time on first-time deploys, breaking count.
  file_system_arn = "*"
}

data "aws_iam_policy_document" "deny_unsecure_transport" {
  count = module.this.enabled && var.deny_unsecure_transport ? 1 : 0

  statement {
    sid       = "DenyUnsecureTransport"
    effect    = "Deny"
    actions   = ["*"]
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
  # Build list of default policy documents to merge.
  default_policy_documents = concat(
    length(data.aws_iam_policy_document.deny_unsecure_transport) > 0 ? [data.aws_iam_policy_document.deny_unsecure_transport[0].json] : [],
    length(data.aws_iam_policy_document.require_tls_version) > 0 ? [data.aws_iam_policy_document.require_tls_version[0].json] : [],
    length(data.aws_iam_policy_document.deny_destructive_operations) > 0 ? [data.aws_iam_policy_document.deny_destructive_operations[0].json] : []
  )
}

data "aws_iam_policy_document" "combined_file_system_policy" {
  count = module.this.enabled && (var.file_system_policy != null || length(local.default_policy_documents) > 0) ? 1 : 0

  source_policy_documents = concat(
    var.file_system_policy != null ? [var.file_system_policy] : [],
    local.default_policy_documents
  )
}

locals {
  # Final merged file system policy JSON.
  file_system_policy_doc = try(data.aws_iam_policy_document.combined_file_system_policy[0].json, null)
}
