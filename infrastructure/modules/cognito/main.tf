locals {
  # userdata = csvdecode(file("${path.module}/user_csvs/${var.csv_file}"))
  userdata = var.userdata
}

# Create user pool
resource "aws_cognito_user_pool" "cognito_user_pool" {
  auto_verified_attributes = [
    "email",
  ]

  deletion_protection = var.deletion_protection
  mfa_configuration   = var.mfa_configuration
  name                = var.name_prefix
  username_attributes = []

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }
  dynamic "schema" {
    for_each = var.attribute_names
    content {
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      name                     = schema.value
      required                 = false

      string_attribute_constraints {
        max_length = "256"
        min_length = "1"
      }
    }
  }
  username_configuration {
    case_sensitive = false
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }
}


resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.domain_name
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
}

resource "aws_cognito_user" "cognito_user_creation" {
  for_each = { for inst in local.userdata : inst.uuid => inst }

  user_pool_id   = aws_cognito_user_pool.cognito_user_pool.id
  username       = each.value.bss_username
  password       = var.user_password
  message_action = var.message_action

  attributes = {
    acr               = var.acr
    amr               = var.amr
    email             = var.user_email
    email_verified    = true
    idassurancelevel  = each.value.id_assurance_level
    nhsid_nrbac_roles = each.value.rbac_role
    bss_username      = each.value.bss_username
    sid               = each.value.uuid
    uid               = each.value.uuid
  }
}

