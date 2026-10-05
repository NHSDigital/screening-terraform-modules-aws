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

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  service     = "bcss"
  environment = "test"
  stack       = "application"
  name        = "hours"
  label_order = ["service", "environment", "stack", "workspace", "name", "attributes"]

  create_bus                 = false
  bus_name                   = "default"
  create_log_delivery_source = false
  create_log_delivery        = false
  kms_key_identifier         = "arn:aws:kms:eu-west-2:111111111111:key/mock"
  role_name                  = "bcss-test-application-default-hours"

  append_schedule_group_postfix = false
  schedule_groups = {
    oracle = {}
  }
}

run "schedule_names_are_context_prefixed" {
  command = plan

  variables {
    append_schedule_postfix = false
    schedules = {
      oracle-start = {
        arn                 = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
        input               = "{\"InstanceIds\":[\"i-123\"]}"
        schedule_expression = "cron(0 7 ? * MON-FRI *)"
        group_name          = "oracle"
        kms_key_arn         = "arn:aws:kms:eu-west-2:111111111111:key/mock"
      }
    }
  }

  assert {
    condition     = keys(module.eventbridge.eventbridge_schedules) == ["bcss-test-application-default-hours-oracle-start"]
    error_message = "Schedule names should be prefixed with the context ID."
  }

  assert {
    condition     = module.eventbridge.eventbridge_schedules["bcss-test-application-default-hours-oracle-start"].group_name == "bcss-test-application-default-hours-oracle"
    error_message = "Schedule group_name should resolve to the prefixed schedule group."
  }
}

run "role_name_defaults_to_context_id" {
  command = plan

  variables {
    role_name = null
    schedules = {
      oracle-stop = {
        arn                 = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
        input               = "{\"InstanceIds\":[\"i-123\"]}"
        schedule_expression = "cron(0 19 ? * MON-FRI *)"
        group_name          = "oracle"
        kms_key_arn         = "arn:aws:kms:eu-west-2:111111111111:key/mock"
      }
    }
  }

  assert {
    condition     = output.eventbridge_role_name == "bcss-test-application-default-hours"
    error_message = "The IAM role should default to the context ID, not the bus name."
  }
}

run "schedule_postfix_is_appended_after_prefix" {
  command = plan

  variables {
    schedules = {
      oracle-stop = {
        arn                 = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
        input               = "{\"InstanceIds\":[\"i-123\"]}"
        schedule_expression = "cron(0 19 ? * MON-FRI *)"
        group_name          = "oracle"
        kms_key_arn         = "arn:aws:kms:eu-west-2:111111111111:key/mock"
      }
    }
  }

  assert {
    condition     = module.eventbridge.eventbridge_schedules["bcss-test-application-default-hours-oracle-stop"].name == "bcss-test-application-default-hours-oracle-stop-schedule"
    error_message = "With append_schedule_postfix, the name should be <context ID>-<key>-schedule."
  }
}
