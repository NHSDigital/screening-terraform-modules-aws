terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.25.0"
    }
  }
}

data "aws_secretsmanager_secret" "release_manager_password" {
  name = "${var.name_prefix}-release_manager"
}

data "aws_secretsmanager_secret_version" "release_manager_password_version" {
  secret_id = data.aws_secretsmanager_secret.release_manager_password.id
}

data "aws_db_instance" "rds" {
  db_instance_identifier = "${var.name_prefix}-${var.rds_name}"
}

locals {
  postgres_secret = jsondecode(data.aws_secretsmanager_secret_version.release_manager_password_version.secret_string)
  endpoint        = data.aws_db_instance.rds.endpoint
  hostname        = split(":", local.endpoint)[0]
}


provider "postgresql" {
  host            = local.hostname
  port            = 5432
  database        = "postgres"
  username        = local.postgres_secret.user
  password        = local.postgres_secret.password
  sslmode         = "require"
  connect_timeout = 15
}

resource "postgresql_database" "my_db" {
  name                   = "${var.name_prefix}-${var.db_name}"
  owner                  = "release_manager"
  lc_collate             = "C"
  connection_limit       = -1
  allow_connections      = true
  alter_object_ownership = true
}
