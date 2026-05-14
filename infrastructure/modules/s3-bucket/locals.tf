################################################################
# Local values
#
# Bucket names are globally unique. Compose from the context id
# and the current AWS region to reduce the chance of collisions
# across accounts and regions. Callers can override the entire
# name via `var.bucket_name`.
################################################################

data "aws_region" "current" {}

locals {
  region_suffix = data.aws_region.current.region

  default_bucket_name = format("%s-%s", module.this.id, local.region_suffix)

  bucket_name = coalesce(var.bucket_name, local.default_bucket_name)

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
}
