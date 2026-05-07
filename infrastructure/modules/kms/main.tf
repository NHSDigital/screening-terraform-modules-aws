module "kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  create                    = module.this.enabled

  # Desired hard-set parameters for the KMS key.
  bypass_policy_lockout_safety_check = false


  aliases_use_name_prefix = var.aliases_use_name_prefix

  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  description             = var.description
  aliases                 = local.aliases
  policy                  = var.policy
  key_usage               = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec


  enable_default_policy = var.enable_default_policy
  key_owners           = var.key_owners
  key_administrators   = var.key_administrators
  key_users = var.key_users
  key_service_users    = var.key_service_users
  key_statements       = var.key_statements


  tags = module.this.tags

}
