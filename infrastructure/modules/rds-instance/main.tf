terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.25.0"
    }
  }
}

provider "postgresql" {
  host             = aws_db_instance.rds.address
  username         = "postgres"
  password         = random_password.password["postgres"].result
  superuser        = false
  expected_version = var.rds_engine_version
}

resource "random_password" "password" {
  for_each         = toset(var.users)
  length           = 20
  special          = true
  override_special = "!%^*-_+="
}

resource "aws_secretsmanager_secret" "password" {
  for_each = toset(var.users)
  name     = "${var.name_prefix}-${each.key}"
}

resource "aws_secretsmanager_secret_version" "password" {
  for_each  = toset(var.users)
  secret_id = aws_secretsmanager_secret.password[each.key].id
  secret_string = jsonencode({
    user     = each.key
    password = random_password.password[each.key].result
  })
}


# locals {
#   subnet_ids = var.environment == "cicd" ? data.aws_subnets.public_subnets.ids : data.aws_subnets.private_subnets.ids
# }

resource "aws_db_subnet_group" "bss" {
  name       = "rds_subnet_group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_parameter_group" "parameter_group" {
  name   = var.name
  family = "postgres${var.rds_engine_version}"

  parameter {
    name         = "max_connections"
    value        = var.db_max_connections
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "client_encoding"
    value        = "UTF8"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "timezone"
    value        = "Europe/London"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "rds.log_retention_period"
    value        = "5760"
    apply_method = "pending-reboot"
  }

  # Add or update the shared_preload_libraries parameter
  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pgaudit"
    apply_method = "pending-reboot"
  }

  # Auditing all user insert,update,delete and ddl
  parameter {
    name         = "log_statement"
    value        = "mod" # Logs INSERT, UPDATE, DELETE, DDL only
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_destination"
    value        = "stderr"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_disconnections"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "rds" {
  identifier                      = "${var.name_prefix}-${var.name}"
  instance_class                  = var.rds_instance_class
  engine                          = var.rds_engine
  engine_version                  = var.rds_engine_version
  username                        = "postgres"
  password                        = random_password.password["postgres"].result
  db_subnet_group_name            = aws_db_subnet_group.bss.id
  allocated_storage               = var.storage
  iops                            = var.storage >= 400 ? var.iops : null # Sets iops to null if storage is less than 400
  storage_encrypted               = var.encryption
  storage_type                    = var.storage_type
  multi_az                        = var.multi_az
  parameter_group_name            = aws_db_parameter_group.parameter_group.id
  skip_final_snapshot             = var.skip_final_snapshot
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = aws_iam_role.enhanced_monitoring.arn
  performance_insights_enabled    = var.performance_insights_enabled
  port                            = var.port
  maintenance_window              = var.maintenance_window
  backup_window                   = var.backup_window
  backup_retention_period         = var.backup_retention_period
  final_snapshot_identifier       = "final-${random_id.final_name.hex}"
  publicly_accessible             = var.publicly_accessible
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  copy_tags_to_snapshot           = var.copy_tags_to_snapshot
  apply_immediately               = var.apply_immediately
  deletion_protection             = var.deletion_protection
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  vpc_security_group_ids          = [aws_security_group.bss.id]
}

resource "aws_iam_role" "enhanced_monitoring" {
  name        = "rds-enhanced-monitoring-role"
  description = "Role for RDS Enhanced Monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "enhanced_monitoring" {
  name        = "rds-enhanced-monitoring-policy"
  description = "Policy for RDS Enhanced Monitoring"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = aws_iam_policy.enhanced_monitoring.arn
}

resource "aws_security_group" "bss" {
  name        = "rds-${var.name}"
  description = "Allow connection by appointed rds postgres clients"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "bss_ingress" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  security_group_id = aws_security_group.bss.id
  cidr_blocks       = var.ingress_cidr
  description       = "Allow access to rds postgres"
}

resource "random_string" "final-name" {
  length           = 16
  special          = true
  override_special = "/@£$"

  lifecycle {
    ignore_changes = [
      length,
      special,
      override_special
    ]
  }
}
resource "random_id" "final_name" {
  byte_length = 1
}

# ROLES

resource "postgresql_role" "release_manager_role" {
  name               = "release_manager"
  login              = true
  password           = random_password.password["release_manager"].result
  encrypted_password = true
  create_database    = true
  inherit            = true
  provider           = postgresql
  search_path = ["$user", "extn_pgtap", "extn_dblink", "extn_postgres_fdw", "extn_file_fdw", "audit", "bss_audit", "bss",
  "bss_migration", "bss_kc63", "bss_sspi", "bss_cspna", "bss_integrity", "bss_support", "pi_4", "bss_reports"]
  depends_on = [aws_db_instance.rds]
}

resource "postgresql_role" "audit_user_role" {
  name               = "audit_user"
  login              = true
  password           = random_password.password["audit_user"].result
  encrypted_password = true
  create_database    = false
  inherit            = true
  provider           = postgresql
  search_path        = ["audit"]
  depends_on         = [aws_db_instance.rds]
}

resource "postgresql_role" "bss_readonly_role" {
  name            = "bss_readonly"
  login           = false
  create_database = false
  inherit         = true
  provider        = postgresql
  depends_on      = [aws_db_instance.rds]
}
resource "postgresql_role" "bss_readwrite_role" {
  name            = "bss_readwrite"
  login           = false
  create_database = false
  inherit         = true
  provider        = postgresql
  depends_on      = [aws_db_instance.rds]
}

resource "postgresql_role" "bss_user_role" {
  name            = "bss_user"
  login           = true
  password        = random_password.password["bss_user"].result
  create_database = false
  inherit         = true
  provider        = postgresql
  search_path = ["$user", "extn_pgtap", "extn_dblink", "extn_postgres_fdw", "extn_file_fdw", "audit", "bss_audit", "bss",
  "bss_migration", "bss_kc63", "bss_sspi", "bss_cspna", "bss_integrity", "bss_support"]
  depends_on = [aws_db_instance.rds]
}

resource "postgresql_role" "pi_4_user_role" {
  name            = "pi_4_user"
  login           = true
  password        = random_password.password["pi_4_user"].result
  create_database = false
  inherit         = true
  provider        = postgresql
  search_path     = ["pi_4"]
  depends_on      = [aws_db_instance.rds]
}

