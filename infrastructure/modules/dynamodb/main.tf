################################################################
# DynamoDB table
#
# Thin NHS wrapper around the community
# terraform-aws-modules/dynamodb-table/aws module that enforces
# the screening platform's baseline controls:
#
#   * Point-in-time recovery — enforced (always on)
#   * Encryption at rest — enforced; AWS-managed by default,
#     CMK via var.kms_key_arn
#   * Deletion protection — enforced (must be disabled before destroy)
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.1"

  create_table = module.this.enabled

  # ----------------------------------------------------------------
  # Naming
  # ----------------------------------------------------------------
  name = local.table_name

  # ----------------------------------------------------------------
  # Key schema
  # ----------------------------------------------------------------
  hash_key   = var.hash_key
  range_key  = var.range_key
  attributes = var.table_attributes

  # ----------------------------------------------------------------
  # Billing
  # ----------------------------------------------------------------
  billing_mode   = var.billing_mode
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity

  # ----------------------------------------------------------------
  # Security baseline (fixed — not exposed as variables)
  # ----------------------------------------------------------------
  point_in_time_recovery_enabled     = true
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = var.kms_key_arn
  deletion_protection_enabled        = true

  # ----------------------------------------------------------------
  # Indexes
  # ----------------------------------------------------------------
  global_secondary_indexes = var.global_secondary_indexes
  local_secondary_indexes  = var.local_secondary_indexes

  # ----------------------------------------------------------------
  # TTL
  # ----------------------------------------------------------------
  ttl_attribute_name = var.ttl_attribute_name
  ttl_enabled        = var.ttl_enabled

  # ----------------------------------------------------------------
  # Streams
  # ----------------------------------------------------------------
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_view_type

  # ----------------------------------------------------------------
  # Tagging
  # ----------------------------------------------------------------
  tags = module.this.tags
}

check "stream_view_type_required" {
  assert {
    condition     = !var.stream_enabled || var.stream_view_type != null
    error_message = "stream_view_type must be set when stream_enabled is true."
  }
}

check "provisioned_capacity_required" {
  assert {
    condition     = var.billing_mode != "PROVISIONED" || (var.read_capacity != null && var.write_capacity != null)
    error_message = "read_capacity and write_capacity must be set when billing_mode is PROVISIONED."
  }
}

check "ttl_attribute_required" {
  assert {
    condition     = !var.ttl_enabled || var.ttl_attribute_name != null
    error_message = "ttl_attribute_name must be set when ttl_enabled is true."
  }
}
