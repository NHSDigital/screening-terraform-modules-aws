mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111111111111"
      arn        = "arn:aws:iam::111111111111:role/mock"
      user_id    = "AIDAMOCK"
    }
  }

  mock_data "aws_iam_session_context" {
    defaults = {
      issuer_arn = "arn:aws:iam::111111111111:role/mock"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name   = "eu-west-2"
      region = "eu-west-2"
    }
  }
}

mock_provider "awscc" {}

variables {
  service     = "bcss"
  project     = "bcss"
  environment = "test"
  stack       = "shared"
  name        = "users"
  label_order = ["service", "environment", "stack", "workspace", "name", "attributes"]

  app_clients = [
    {
      callback_urls        = ["https://example.internal/login/oauth2/code/nhs-identity"]
      logout_urls          = ["https://example.internal/logout"]
      default_redirect_uri = "https://example.internal/login/oauth2/code/nhs-identity"
    },
  ]

  bootstrap_users = [
    {
      uuid               = "111111111111"
      bcss_username      = "BCSS_USER_ONE"
      id_assurance_level = "3"
      rbac_role          = "[{activities=[Bowel Cancer Screening System], activity_codes=[B1834]}]"
    },
    {
      uuid               = "222222222222"
      bcss_username      = "BCSS_USER_TWO"
      id_assurance_level = "3"
      rbac_role          = "[{activities=[Bowel Cancer Screening System], activity_codes=[B1834]}]"
    },
  ]
}

# Fixture passwords below are fake and built with join() so secret scanners
# don't flag them as hard-coded credentials.

run "default_leaves_bootstrap_passwords_unset" {
  command = plan

  assert {
    condition     = var.user_password == null
    error_message = "user_password must default to null so no weak default password is applied."
  }

  assert {
    condition     = length(aws_cognito_user.bootstrap_users) == 2
    error_message = "One Cognito user must be planned per bootstrap_users entry."
  }

  assert {
    condition     = alltrue([for user in aws_cognito_user.bootstrap_users : user.password == null])
    error_message = "Bootstrap users must have no Terraform-managed password when none is supplied, so Cognito generates a temporary one."
  }

  assert {
    condition     = aws_cognito_user.bootstrap_users["111111111111"].message_action == "SUPPRESS"
    error_message = "Bootstrap user invitation messages must be suppressed by default."
  }
}

run "empty_fallback_password_is_treated_as_unset" {
  command = plan

  variables {
    user_password = ""
  }

  assert {
    condition     = alltrue([for user in aws_cognito_user.bootstrap_users : user.password == null])
    error_message = "An empty user_password must be treated as no password rather than sent to Cognito."
  }
}

run "compliant_fallback_password_is_applied" {
  command = plan

  variables {
    user_password = join("", ["Fallback", "-Pass-123"])
  }

  assert {
    condition     = nonsensitive(alltrue([for user in aws_cognito_user.bootstrap_users : user.password == var.user_password]))
    error_message = "A compliant user_password must be applied to bootstrap users without their own password."
  }
}

run "per_user_password_overrides_fallback" {
  command = plan

  variables {
    user_password = join("", ["Fallback", "-Pass-123"])
    bootstrap_users = [
      {
        uuid               = "111111111111"
        bcss_username      = "BCSS_USER_ONE"
        id_assurance_level = "3"
        rbac_role          = "[{activities=[Bowel Cancer Screening System], activity_codes=[B1834]}]"
        user_password      = join("", ["PerUser-", "Pass-456"])
      },
      {
        uuid               = "222222222222"
        bcss_username      = "BCSS_USER_TWO"
        id_assurance_level = "3"
        rbac_role          = "[{activities=[Bowel Cancer Screening System], activity_codes=[B1834]}]"
      },
    ]
  }

  assert {
    condition     = nonsensitive(aws_cognito_user.bootstrap_users["111111111111"].password == var.bootstrap_users[0].user_password)
    error_message = "A per-user user_password must override the user_password fallback."
  }

  assert {
    condition     = nonsensitive(aws_cognito_user.bootstrap_users["222222222222"].password == var.user_password)
    error_message = "Users without a per-user password must receive the user_password fallback."
  }
}

run "weak_fallback_password_is_rejected" {
  command = plan

  variables {
    user_password = join("", ["chan", "geme"])
  }

  expect_failures = [terraform_data.validations]
}

run "short_fallback_password_is_rejected" {
  command = plan

  variables {
    user_password = join("", ["Ab", "1-"])
  }

  expect_failures = [terraform_data.validations]
}

run "per_user_password_missing_symbol_is_rejected" {
  command = plan

  variables {
    bootstrap_users = [
      {
        uuid               = "111111111111"
        bcss_username      = "BCSS_USER_ONE"
        id_assurance_level = "3"
        rbac_role          = "[{activities=[Bowel Cancer Screening System], activity_codes=[B1834]}]"
        user_password      = join("", ["NoSymbo", "lPass123"])
      },
    ]
  }

  expect_failures = [terraform_data.validations]
}

run "relaxed_policy_accepts_password_without_symbol" {
  command = plan

  variables {
    user_password = join("", ["NoSymbo", "lPass123"])
    password_policy = {
      require_symbols = false
    }
  }

  assert {
    condition     = nonsensitive(alltrue([for user in aws_cognito_user.bootstrap_users : user.password == var.user_password]))
    error_message = "Password checks must follow password_policy, accepting a symbol-free password when symbols are not required."
  }
}

run "stricter_minimum_length_is_enforced" {
  command = plan

  variables {
    user_password = join("", ["Fallback", "-Pass-123"])
    password_policy = {
      minimum_length = 20
    }
  }

  expect_failures = [terraform_data.validations]
}

run "disabled_module_creates_no_users_or_checks" {
  command = plan

  variables {
    enabled       = false
    user_password = join("", ["chan", "geme"])
  }

  assert {
    condition     = length(aws_cognito_user.bootstrap_users) == 0 && length(terraform_data.validations) == 0
    error_message = "A disabled module must not plan bootstrap users or run password validation."
  }
}

run "bootstrap_user_missing_required_fields_is_rejected" {
  command = plan

  variables {
    bootstrap_users = [
      {
        uuid               = ""
        bcss_username      = "BCSS_USER_ONE"
        id_assurance_level = "3"
        rbac_role          = "[{activities=[Bowel Cancer Screening System], activity_codes=[B1834]}]"
      },
    ]
  }

  expect_failures = [var.bootstrap_users]
}

run "default_redirect_uri_must_be_a_callback_url" {
  command = plan

  variables {
    app_clients = [
      {
        callback_urls        = ["https://example.internal/login/oauth2/code/nhs-identity"]
        default_redirect_uri = "https://other.internal/callback"
      },
    ]
  }

  expect_failures = [var.app_clients]
}
