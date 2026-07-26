locals {
  # Override the cloudposse IAM group name to follow NHS context-based naming conventions.
  # Without this, cloudposse's label module would generate its own name
  # that does not align with the NHS screening platform's standard.
  ses_group_name = module.this.id
}
