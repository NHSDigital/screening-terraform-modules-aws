terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.25.0"
    }
  }
}

resource "random_password" "password" {
  length           = 20
  special          = true
  override_special = "!%^*-_+="
}

resource "aws_secretsmanager_secret" "password" {
  name                    = "${var.name_prefix}-${var.user}"
  recovery_window_in_days = var.recovery_window

  dynamic "replica" {
    for_each = var.secret_replication_regions
    content {
      region = replica.value
    }
  }
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id = aws_secretsmanager_secret.password.id
  secret_string = jsonencode({
    user     = var.user
    password = random_password.password.result
  })
}

resource "aws_db_subnet_group" "private_bss" {
  name       = "${var.name_prefix}-rds-private-${var.name}"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_parameter_group" "parameter_group" {
  name   = "${var.name_prefix}-${var.name}-${var.rds_engine_version}"
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
    value        = "none"
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "rds" {
  identifier                            = "${var.name_prefix}-${var.name}"
  instance_class                        = var.rds_instance_class
  engine                                = var.rds_engine
  engine_version                        = var.rds_engine_version
  username                              = "postgres"
  password                              = random_password.password.result
  db_subnet_group_name                  = aws_db_subnet_group.private_bss.id
  allocated_storage                     = var.storage
  iops                                  = var.storage >= 400 ? var.iops : null # Sets iops to null if storage is less than 400
  storage_encrypted                     = var.encryption
  storage_type                          = var.storage_type
  multi_az                              = var.multi_az
  parameter_group_name                  = aws_db_parameter_group.parameter_group.id
  skip_final_snapshot                   = var.skip_final_snapshot
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = aws_iam_role.enhanced_monitoring.arn
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  database_insights_mode                = var.database_insights_mode
  port                                  = var.port
  maintenance_window                    = var.maintenance_window
  backup_window                         = var.backup_window
  backup_retention_period               = var.backup_retention_period
  final_snapshot_identifier             = "final-${random_id.final_name.hex}"
  publicly_accessible                   = var.publicly_accessible
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot
  apply_immediately                     = var.apply_immediately
  deletion_protection                   = var.deletion_protection
  allow_major_version_upgrade           = var.allow_major_version_upgrade
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports # log group is created automatically by aws_db_instance, no need to create separately
  vpc_security_group_ids                = [aws_security_group.rds.id]
  tags                                  = var.tags

  snapshot_identifier = var.snapshot_identifier != "" ? var.snapshot_identifier : null

  lifecycle {
    ignore_changes = [
      snapshot_identifier
    ]
  }
}

resource "aws_iam_role" "enhanced_monitoring" {
  name        = "${var.name_prefix}-rds-enhanced-monitoring"
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
  name        = "${var.name_prefix}-rds-enhanced-monitoring"
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

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-${var.name}"
  description = "Allow connection by appointed rds postgres clients"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ecs_ingress" {
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = var.ecs_sg_id
  description              = "Allow ecs access to rds postgres"
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
