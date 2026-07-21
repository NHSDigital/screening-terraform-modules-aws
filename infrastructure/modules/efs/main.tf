################################################################
# EFS (Elastic File System)
#
# Thin NHS wrapper around the community terraform-aws-modules/efs/aws
# module that enforces the screening platform's baseline controls:
#
#   * Encryption: KMS encryption at rest is mandatory
#   * Transport: NFSv4.1 security groups are caller-supplied (required)
#   * Throughput: caller controls performance mode and throughput mode
#   * Access: optional backup/transition lifecycle policies
#   * Policy: auto-generated security statements for transport, TLS, IPs, and destructive ops
#
# Naming and tagging are derived from context.tf via module.this.
# Cross-variable input constraints are enforced in validations.tf.
################################################################

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "2.2.0"

  create = module.this.enabled

  # ----------------------------------------------------------------
  # Naming and metadata.
  # ----------------------------------------------------------------
  name           = local.efs_name
  creation_token = var.creation_token

  # ----------------------------------------------------------------
  # Encryption at rest: mandatory KMS encryption.
  # ----------------------------------------------------------------
  encrypted   = true
  kms_key_arn = var.kms_key_arn

  # ----------------------------------------------------------------
  # Performance and throughput modes. Defaults are suitable for
  # general purpose; caller can override for higher-performance needs.
  # ----------------------------------------------------------------
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  # ----------------------------------------------------------------
  # Transition and lifecycle policies (optional).
  # ----------------------------------------------------------------
  lifecycle_policy = var.lifecycle_policy

  # ----------------------------------------------------------------
  # Mount targets: caller must provide security group(s) and subnets.
  # ----------------------------------------------------------------
  mount_targets = var.mount_targets

  # ----------------------------------------------------------------
  # Backup policy (optional).
  # ----------------------------------------------------------------
  create_backup_policy = var.protection.enable_backup
  enable_backup_policy = var.protection.enable_backup

  # ----------------------------------------------------------------
  # Replication configuration (optional).
  # ----------------------------------------------------------------
  create_replication_configuration      = length(var.replication_configuration) > 0
  replication_configuration_destination = var.replication_configuration

  # ----------------------------------------------------------------
  # Tagging: all resources tagged via module.this.
  # ----------------------------------------------------------------
  tags = module.this.tags
}

################################################################
# File System Policy (optional, resource-based access control)
################################################################

resource "aws_efs_file_system_policy" "this" {
  count = module.this.enabled && local.file_system_policy_doc != null ? 1 : 0

  file_system_id = module.efs.id
  policy         = local.file_system_policy_doc

  depends_on = [module.efs]
}

################################################################
# Access Points (optional, application-level isolation)
################################################################
resource "aws_efs_access_point" "this" {
  for_each = module.this.enabled ? var.access_points : {}

  file_system_id = module.efs.id

  # Root directory enforces a chroot jail for the access point
  root_directory {
    path = each.value.root_directory_path

    creation_info {
      owner_gid   = each.value.enforced_user_id
      owner_uid   = each.value.enforced_user_id
      permissions = each.value.permissions_mode
    }
  }

  # Enforce a POSIX user identity for all requests through this access point
  posix_user {
    gid = each.value.enforced_user_id
    uid = each.value.enforced_user_id
  }

  tags = merge(
    module.this.tags,
    {
      Name = "${module.this.id}-${each.key}"
    }
  )

  depends_on = [module.efs]
}
