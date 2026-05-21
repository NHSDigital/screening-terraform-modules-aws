################################################################
# S3 bucket
#
# Thin NHS wrapper around the community S3 bucket module that
# enforces the screening platform's baseline controls:
#
#   * Ownership: BucketOwnerEnforced
#   * Encryption: SSE enabled by default, denies for unencrypted
#     or incorrectly encrypted uploads
#   * Transport: TLS-only
#   * Versioning: enabled by default
#   * Public access: blocked at all four toggles
#   * Logging: optional, delivered to a caller-supplied bucket
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"

  create_bucket = module.this.enabled

  # Naming. Caller can override the full name via var.bucket_name;
  # otherwise the name is `<module.this.id>-<region>` to keep the
  # global S3 namespace collision-free.
  bucket = local.bucket_name

  force_destroy = var.force_destroy

  # ----------------------------------------------------------------
  # Ownership: BucketOwnerEnforced disables ACLs entirely.
  # ----------------------------------------------------------------
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # ----------------------------------------------------------------
  # Public access block (all four toggles on).
  # ----------------------------------------------------------------
  attach_public_policy    = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # ----------------------------------------------------------------
  # Transport: deny non-TLS connections and require the latest TLS.
  # ----------------------------------------------------------------
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  # ----------------------------------------------------------------
  # Encryption: SSE by default; reject unencrypted or
  # incorrectly encrypted PutObject requests.
  # ----------------------------------------------------------------
  server_side_encryption_configuration = local.server_side_encryption_configuration

  attach_deny_unencrypted_object_uploads    = true
  attach_deny_incorrect_encryption_headers  = true
  attach_deny_ssec_encrypted_object_uploads = true
  # NOTE: must be a value that is known at plan time, because the
  # upstream module uses it inside a `count` argument. Deriving it
  # from `var.kms_master_key_arn != null` breaks plans on first
  # apply when the KMS key is created in the same configuration.
  attach_deny_incorrect_kms_key_sse = coalesce(var.attach_deny_incorrect_kms_key_sse, var.kms_master_key_arn != null)
  allowed_kms_key_arn               = var.kms_master_key_arn

  # ----------------------------------------------------------------
  # Versioning (default: enabled).
  # ----------------------------------------------------------------
  versioning = local.versioning

  # ----------------------------------------------------------------
  # Access logging to a caller-supplied target bucket.
  # ----------------------------------------------------------------
  logging = var.logging

  # ----------------------------------------------------------------
  # Optional pass-throughs.
  # ----------------------------------------------------------------
  lifecycle_rule = var.lifecycle_rule
  cors_rule      = var.cors_rule

  # Custom bucket policy (merged by the upstream module with the
  # generated deny-statements above).
  attach_policy = var.policy != null
  policy        = var.policy

  tags = module.this.tags
}
