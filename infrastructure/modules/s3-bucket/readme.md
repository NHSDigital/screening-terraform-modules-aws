# S3

NHS Screening wrapper around the community
[`terraform-aws-modules/s3-bucket/aws`](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest)
module that enforces the platform's baseline controls and consumes
the shared `context.tf` for naming and tagging.

## What this module enforces

| Control                  | How it is enforced                                                                |
| ------------------------ | --------------------------------------------------------------------------------- |
| Ownership                | `object_ownership = "BucketOwnerEnforced"` (ACLs disabled)                        |
| Transport (TLS)          | `attach_deny_insecure_transport_policy` + `attach_require_latest_tls_policy`      |
| Encryption at rest       | SSE-S3 by default; SSE-KMS when `kms_master_key_arn` is set                       |
| Encryption on PUT        | Denies unencrypted, incorrect-header, SSEC and wrong-KMS-key PutObject calls      |
| Public access            | All four S3 public-access-block toggles set to true                               |
| Versioning               | Enabled by default; opt out with `versioning_enabled = false`                     |
| Globally unique name     | Default name is `<module.this.id>-<aws_region>`                                   |
| Logging                  | Optional, delivered to a caller-supplied target bucket via `var.logging`          |

## Usage

### Minimal bucket (versioning on, SSE-S3, name auto-derived)

```hcl
module "data_bucket" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/s3?ref=main"

  service     = "bcss"
  project     = "ingest"
  environment = "development"
  name        = "raw-data"
}
```

### Bucket with KMS encryption and access logging

```hcl
module "audit_bucket" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/s3?ref=main"

  service     = "bcss"
  project     = "audit"
  environment = "prod"
  name        = "audit-events"

  kms_master_key_arn = module.audit_kms.key_arn

  logging = {
    target_bucket = module.log_bucket.bucket_id
    target_prefix = "s3/audit-events/"
  }
}
```

### Logging-target bucket (receives logs from other buckets)

```hcl
module "log_bucket" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/s3?ref=main"

  service     = "bcss"
  project     = "platform"
  environment = "prod"
  name        = "s3-access-logs"

  versioning_enabled = false
}
```

## Conventions

* `bucket_name` defaults to `<module.this.id>-<region>` so the same Terraform
  configuration produces a different bucket in each region without manual
  intervention.
* `force_destroy` defaults to `false`. Only set it to `true` for short-lived
  buckets that will never hold business data.
* Custom bucket policies provided via `var.policy` are merged by the upstream
  module with the platform's deny-non-TLS and deny-unencrypted statements; you
  do not need to restate those rules.

## What this module does NOT do

* Create a KMS key. Use the `kms` module and pass `key_arn` in via
  `kms_master_key_arn`.
* Manage replication, object-lock, intelligent storage classes, website hosting,
  inventory, or analytics configurations. Add a dedicated wrapper or use the
  upstream module directly if you need those.
* Configure account-level public-access-block. That belongs in an account-scope
  module, not a per-bucket one.

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
<!-- terraform-docs regenerates the content below in CI. -->
<!-- END_TF_DOCS -->
<!-- vale on -->
