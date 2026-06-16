provider "postgresql" {
  host             = var.rds_endpoint
  username         = "postgres"
  password         = var.rds_password
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
  for_each                = toset(var.users)
  name                    = "${var.name_prefix}-${each.key}"
  recovery_window_in_days = var.recovery_window

  dynamic "replica" {
    for_each = var.secret_replication_regions
    content {
      region = replica.value
    }
  }
}

resource "aws_secretsmanager_secret_version" "password" {
  for_each  = toset(var.users)
  secret_id = aws_secretsmanager_secret.password[each.key].id
  secret_string = jsonencode({
    user     = each.key
    password = random_password.password[each.key].result
  })
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
}

resource "postgresql_role" "bss_readonly_role" {
  name            = "bss_readonly"
  login           = false
  create_database = false
  inherit         = true
  provider        = postgresql
}
resource "postgresql_role" "bss_readwrite_role" {
  name            = "bss_readwrite"
  login           = false
  create_database = false
  inherit         = true
  provider        = postgresql
}

resource "postgresql_role" "bss_user_role" {
  name            = "bss_user"
  login           = true
  password        = random_password.password["bss_user"].result
  create_database = false
  inherit         = true
  provider        = postgresql
  search_path     = ["$user", "extn_pgtap", "extn_dblink", "extn_postgres_fdw", "extn_file_fdw", "audit", "bss_audit", "bss", "bss_migration", "bss_kc63", "bss_sspi", "bss_cspna", "bss_integrity", "bss_support"]
}

resource "postgresql_role" "pi_4_user_role" {
  name            = "pi_4_user"
  login           = true
  password        = random_password.password["pi_4_user"].result
  create_database = false
  inherit         = true
  provider        = postgresql
  search_path     = ["pi_4"]
}
