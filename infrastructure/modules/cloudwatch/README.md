# CloudWatch

NHS Screening wrapper around selected submodules from the
[terraform-aws-modules CloudWatch module](https://registry.terraform.io/modules/terraform-aws-modules/cloudwatch/aws/latest)
that provides a single module entry point for common CloudWatch log and alarm building blocks.

## Included submodules

- `log-group`
- `log-stream`
- `log-metric-filter`
- `metric-alarm`
- `metric-alarms-by-multiple-dimensions`

## What this module enforces

| Control | How it is enforced |
| ------- | ------------------ |
| Single entry point | One shared wrapper exposes the requested CloudWatch submodules together |
| Creation gate | Each submodule is gated by `module.this.enabled` and a non-null config object |
| Naming | Names are derived from `module.this.id` |
| Tagging | Log groups and alarms that support tags receive `module.this.tags` |
| Minimal interface | Only the minimal required or functionally necessary configuration is exposed |

## Usage

### Complete example

```hcl
module "cloudwatch" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cloudwatch?ref=main"

  service     = "bcss"
  project     = "shared-resources"
  environment = "prod"
  stack       = "monitoring"
  name        = "application"

  log_group = {}

  log_stream = {}

  log_metric_filter = {
    pattern                         = "ERROR"
    metric_transformation_name      = "ErrorCount"
    metric_transformation_namespace = "BCSS/Application"
  }

  metric_alarm = {
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    threshold           = 10
  }

  metric_alarms_by_multiple_dimensions = {
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    threshold           = 10
    dimensions = {
      lambda1 = {
        FunctionName = "function-one"
      }
      lambda2 = {
        FunctionName = "function-two"
      }
    }
  }
}
```

## Conventions

- Set a submodule object to `null` to skip creating that submodule.
- `log_stream` and `log_metric_filter` depend on `log_group` being configured in the same module call.
- `metric_alarm` and `metric_alarms_by_multiple_dimensions` derive their metric name and namespace from `log_metric_filter`.
- `metric_alarm` uses fixed defaults of `period = "60"` and `statistic = "Sum"`.
- `metric_alarms_by_multiple_dimensions` uses fixed defaults of `period = "60"` and `statistic = "Sum"`.
- CloudWatch log streams and log metric filters do not support tags directly, so only the submodules that accept tags receive `module.this.tags`.
