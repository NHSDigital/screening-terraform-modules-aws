################################################################
# Local values
#
# Bucket names are globally unique. Compose from the context id
# and the current AWS region to reduce the chance of collisions
# across accounts and regions. Callers can override the entire
# name via `var.bucket_name`.
################################################################

locals {

  default_bucket_name = format("%s", module.this.id)

  # TODO: Consider adding a region suffix to the bucket name to reduce the chance of collisions across accounts and regions. This would require updating all existing stacks that use this module, so it is not done yet.
  # data "aws_region" "current" {}
  # region_suffix = data.aws_region.current.region
  # default_bucket_name = format("%s-%s", module.this.id, local.region_suffix)
  bucket_name = module.this.enabled ? coalesce(var.bucket_name, local.default_bucket_name) : null

  # Versioning is enabled by default. Callers can suspend it by
  # setting `var.versioning_enabled = false`.
  versioning = {
    enabled = var.versioning_enabled
  }

  # Default server-side encryption. SSE-S3 (AES256) is applied
  # when no KMS key ARN is provided; otherwise SSE-KMS is used.
  default_sse_configuration = {
    rule = {
      apply_server_side_encryption_by_default = var.kms_master_key_arn == null ? {
        sse_algorithm = "AES256"
        } : {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = var.kms_master_key_arn
      }
      bucket_key_enabled = true
    }
  }

  server_side_encryption_configuration = length(var.server_side_encryption_configuration) > 0 ? var.server_side_encryption_configuration : local.default_sse_configuration

  bucket_policy = var.allow_lb_log_delivery_without_encryption_headers ? data.aws_iam_policy_document.lb_log_delivery_encryption_exception[0].json : var.policy
  bucket_arn    = "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_name}"
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "lb_log_delivery_encryption_exception" {
  count = var.allow_lb_log_delivery_without_encryption_headers ? 1 : 0

  source_policy_documents = compact([var.policy])

  statement {
    sid    = "DenyUnencryptedUploadsExceptLoadBalancerDelivery"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/*"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalServiceName"
      values   = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    sid    = "DenyIncorrectEncryptionHeaders"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/*"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["false"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
}
