mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      arn = "arn:aws:iam::111111111111:role/mock"
    }
  }

  mock_data "aws_iam_session_context" {
    defaults = {
      issuer_arn = "arn:aws:iam::111111111111:role/mock"
    }
  }

  mock_resource "aws_ssm_parameter" {
    defaults = {
      arn     = "arn:aws:ssm:eu-west-2:111111111111:parameter/mock"
      version = 1
    }
  }
}

variables {
  service     = "bcss"
  environment = "test"
  stack       = "application"
  delimiter   = "/"
  name        = "MY_KEY"

  label_value_case = "none"
  label_order      = ["service", "environment", "stack", "workspace", "name", "attributes"]
}

# All runs use plan: terraform test cannot re-supply ephemeral inputs to the apply phase.

run "string_parameter" {
  command = plan

  variables {
    type  = "String"
    value = "plain-value"
  }

  assert {
    condition     = aws_ssm_parameter.this[0].name == "/bcss/test/application/default/MY_KEY"
    error_message = "Path-style name should be derived from context labels with case preserved."
  }

  assert {
    condition     = aws_ssm_parameter.this[0].insecure_value == "plain-value"
    error_message = "String value should be stored as insecure_value."
  }

  assert {
    condition     = aws_ssm_parameter.this[0].value_wo_version == null
    error_message = "String parameters must not use write-only arguments."
  }

  assert {
    condition     = output.value == "plain-value"
    error_message = "value output should expose the String value."
  }
}

run "string_list_parameter" {
  command = plan

  variables {
    type   = "StringList"
    values = ["a", "b"]
  }

  assert {
    condition     = aws_ssm_parameter.this[0].insecure_value == jsonencode(["a", "b"])
    error_message = "StringList values should be JSON-encoded."
  }
}

run "secure_string_ephemeral_value" {
  command = plan

  variables {
    type             = "SecureString"
    key_id           = "arn:aws:kms:eu-west-2:111111111111:key/mock"
    value_wo         = "super-secret"
    value_wo_version = 3
  }

  assert {
    condition     = aws_ssm_parameter.this[0].type == "SecureString"
    error_message = "Parameter type should be SecureString."
  }

  assert {
    condition     = aws_ssm_parameter.this[0].value_wo_version == 3 && aws_ssm_parameter.this[0].key_id == var.key_id
    error_message = "SecureString must use the supplied value_wo_version and key_id."
  }

  assert {
    condition     = output.secure_type
    error_message = "secure_type output should be true."
  }
}

run "secure_string_value_routed_to_write_only" {
  command = plan

  variables {
    type             = "SecureString"
    key_id           = "arn:aws:kms:eu-west-2:111111111111:key/mock"
    value            = "legacy-input"
    value_wo_version = 1
  }

  assert {
    condition     = aws_ssm_parameter.this[0].type == "SecureString" && aws_ssm_parameter.this[0].value_wo_version == 1
    error_message = "value for a SecureString must be accepted and sent via the write-only argument."
  }
}

run "ignore_value_changes" {
  command = plan

  variables {
    type                 = "SecureString"
    key_id               = "arn:aws:kms:eu-west-2:111111111111:key/mock"
    value_wo             = "seed"
    value_wo_version     = 1
    ignore_value_changes = true
  }

  assert {
    condition     = length(aws_ssm_parameter.this) == 0 && length(aws_ssm_parameter.ignore_value) == 1
    error_message = "ignore_value_changes should use the ignore_value resource."
  }
}

run "parameter_name_override" {
  command = plan

  variables {
    type           = "String"
    value          = "x"
    parameter_name = "/custom/path"
  }

  assert {
    condition     = aws_ssm_parameter.this[0].name == "/custom/path"
    error_message = "parameter_name should override the context-derived name."
  }
}

run "disabled" {
  command = plan

  variables {
    enabled = false
    type    = "SecureString"
  }

  assert {
    condition     = length(aws_ssm_parameter.this) == 0 && length(aws_ssm_parameter.ignore_value) == 0
    error_message = "No resources should be created when disabled."
  }
}

run "secure_string_requires_version" {
  command = plan

  variables {
    type     = "SecureString"
    key_id   = "arn:aws:kms:eu-west-2:111111111111:key/mock"
    value_wo = "secret"
  }

  expect_failures = [var.value_wo_version]
}

run "secure_string_requires_key" {
  command = plan

  variables {
    type             = "SecureString"
    value_wo         = "secret"
    value_wo_version = 1
  }

  expect_failures = [var.key_id]
}

run "value_wo_rejected_for_non_secure" {
  command = plan

  variables {
    type     = "StringList"
    values   = ["a"]
    value_wo = "secret"
  }

  expect_failures = [var.value_wo]
}

run "values_rejected_for_string" {
  command = plan

  variables {
    type   = "String"
    values = ["a"]
  }

  expect_failures = [var.values]
}

run "value_and_value_wo_mutually_exclusive" {
  command = plan

  variables {
    type             = "SecureString"
    key_id           = "arn:aws:kms:eu-west-2:111111111111:key/mock"
    value            = "a"
    value_wo         = "b"
    value_wo_version = 1
  }

  expect_failures = [var.value_wo]
}

run "string_requires_value" {
  command = plan

  variables {
    type = "String"
  }

  expect_failures = [var.value]
}
