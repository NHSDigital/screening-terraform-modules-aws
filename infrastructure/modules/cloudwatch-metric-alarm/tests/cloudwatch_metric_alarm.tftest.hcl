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

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  service     = "bcss"
  project     = "bcss"
  environment = "test"
  stack       = "account"
  name        = "oracle-licence"
  label_order = ["service", "environment", "stack", "workspace", "name", "attributes"]
}

run "single_metric_alarm_only" {
  command = apply

  variables {
    metric_alarm = {
      metric_name         = "ExampleMetric"
      namespace           = "Example/Tests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      threshold           = 1
    }
  }

  assert {
    condition     = output.cloudwatch_metric_alarm_id != null
    error_message = "A configured single metric alarm must return its alarm ID."
  }

  assert {
    condition     = output.cloudwatch_metric_alarms_by_multiple_dimensions_ids == {}
    error_message = "The unused multi-dimension alarm output must stay empty when only a single alarm is configured."
  }

  assert {
    condition     = local.single_metric_alarm.period == 60 && local.single_metric_alarm.actions_enabled
    error_message = "A single metric alarm must default to a 60-second period with actions enabled."
  }

  assert {
    condition     = var.treat_missing_data == "missing"
    error_message = "Missing data must default to missing when no value is supplied."
  }
}

run "multi_dimension_alarm_only" {
  command = apply

  variables {
    metric_alarms_by_multiple_dimensions = {
      metric_name         = "ExampleMetric"
      namespace           = "Example/Tests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      threshold           = 1
      dimensions          = { Family = "integration" }
    }
  }

  assert {
    condition     = length(output.cloudwatch_metric_alarms_by_multiple_dimensions_ids) == 1
    error_message = "A configured multi-dimension alarm must return one alarm ID."
  }

  assert {
    condition     = output.cloudwatch_metric_alarm_id == null
    error_message = "The unused single-alarm output must stay null when only a multi-dimension alarm is configured."
  }

  assert {
    condition     = local.multi_dimension_metric_alarm.period == 60 && local.multi_dimension_metric_alarm.dimensions["Family"] == "integration"
    error_message = "A multi-dimension alarm must preserve its dimensions and default to a 60-second period."
  }
}

run "both_alarm_types_allow_custom_periods_and_disabled_actions" {
  command = plan

  variables {
    metric_alarm = {
      metric_name         = "ShortWindowMetric"
      namespace           = "Example/Tests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      threshold           = 1
      period              = 300
      actions_enabled     = false
    }

    metric_alarms_by_multiple_dimensions = {
      metric_name         = "HourlyMetric"
      namespace           = "Example/Tests"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      threshold           = 80
      period              = 3600
      actions_enabled     = false
      dimensions          = { Family = "integration" }
    }
  }

  assert {
    condition = (
      var.metric_alarm != null &&
      var.metric_alarms_by_multiple_dimensions != null &&
      local.single_metric_alarm.period == 300 &&
      !local.single_metric_alarm.actions_enabled &&
      local.multi_dimension_metric_alarm.period == 3600 &&
      !local.multi_dimension_metric_alarm.actions_enabled
    )
    error_message = "Both alarm inputs must support independent periods and disabled actions."
  }
}

run "ignore_missing_data_value_is_accepted" {
  command = plan

  variables {
    metric_alarm = {
      metric_name         = "ExampleMetric"
      namespace           = "Example/Tests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      threshold           = 1
    }
    treat_missing_data = "ignore"
  }

  assert {
    condition     = var.treat_missing_data == "ignore"
    error_message = "The CloudWatch-supported ignore value must be accepted for missing data."
  }
}

run "invalid_missing_data_value_is_rejected" {
  command = plan

  variables {
    metric_alarm = {
      metric_name         = "ExampleMetric"
      namespace           = "Example/Tests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      threshold           = 1
    }
    treat_missing_data = "ignoreMetricTime"
  }

  expect_failures = [var.treat_missing_data]
}

run "at_least_one_alarm_configuration_is_required" {
  command = plan

  expect_failures = [check.at_least_one_alarm_configured]
}
