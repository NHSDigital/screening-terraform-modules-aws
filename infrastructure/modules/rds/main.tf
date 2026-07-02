# ----------------------------------------------------------------------------
# RDS instance
#
# Wraps terraform-aws-modules/rds/aws v7.2.0.
#
# Fixed controls (not exposed as variables):
#   - publicly_accessible   = false  (databases must never be internet-facing)
#   - storage_encrypted     = true   (encryption at rest is mandatory)
#   - copy_tags_to_snapshot = true   (snapshots must carry the same tags)
#   - auto_minor_version_upgrade = false (teams keep instances in sync with prod)
#   - create_db_subnet_group = true  (subnet group always managed by this module)
# ----------------------------------------------------------------------------

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.2.0"

  create_db_instance        = module.this.enabled
  create_db_subnet_group    = module.this.enabled
  create_db_parameter_group = module.this.enabled
  create_db_option_group    = module.this.enabled

  identifier = local.rds_identifier

  # Engine
  engine             = var.engine
  engine_version     = var.engine_version
  license_model      = var.license_model
  character_set_name = var.character_set_name

  # Instance sizing
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_encrypted     = true
  kms_key_id            = var.kms_key_id

  # Database
  db_name  = var.db_name
  username = var.username
  port     = var.port

  # Credentials
  manage_master_user_password = var.manage_master_user_password
  password_wo                 = var.password_wo
  password_wo_version         = var.password_wo_version

  # Networking
  publicly_accessible    = false
  vpc_security_group_ids = var.vpc_security_group_ids

  # Subnet group (always managed by this module)
  subnet_ids = var.subnet_ids

  # Parameter group
  family     = var.family
  parameters = var.parameters

  # Option group
  major_engine_version = var.major_engine_version
  options              = var.options

  # Monitoring
  monitoring_interval    = var.monitoring_interval
  create_monitoring_role = module.this.enabled && var.monitoring_interval > 0

  # Availability and backup
  multi_az                   = var.multi_az
  backup_retention_period    = var.backup_retention_period
  backup_window              = var.backup_window
  maintenance_window         = var.maintenance_window
  skip_final_snapshot        = var.skip_final_snapshot
  snapshot_identifier        = var.snapshot_identifier
  apply_immediately          = var.apply_immediately
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = false

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id

  # Lifecycle
  deletion_protection = var.deletion_protection

  timeouts = var.timeouts

  tags = module.this.tags
}
