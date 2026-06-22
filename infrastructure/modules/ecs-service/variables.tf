variable "alarms" {
  description = "Information about the CloudWatch alarms"
  type = object({
    alarm_names = list(string)
    enable      = optional(bool, true)
    rollback    = optional(bool, true)
  })
  default = null
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI (Fargate launch type only)"
  type        = bool
  default     = false
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks to run in your service"
  type        = number
  default     = 10
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks to run in your service"
  type        = number
  default     = 1
}

variable "autoscaling_policies" {
  description = "Map of autoscaling policies to create for the service"
  type = map(object({
    name        = optional(string) # Will fall back to the key name if not provided
    policy_type = optional(string, "TargetTrackingScaling")
    predictive_scaling_policy_configuration = optional(object({
      max_capacity_breach_behavior = optional(string)
      max_capacity_buffer          = optional(number)
      metric_specification = list(object({
        customized_capacity_metric_specification = optional(object({
          metric_data_query = list(object({
            expression = optional(string)
            id         = string
            label      = optional(string)
            metric_stat = optional(object({
              metric = object({
                dimension = optional(list(object({
                  name  = string
                  value = string
                })))
                metric_name = optional(string)
                namespace   = optional(string)
              })
              stat = string
              unit = optional(string)
            }))
            return_data = optional(bool)
          }))
        }))
        customized_load_metric_specification = optional(object({
          metric_data_query = list(object({
            expression = optional(string)
            id         = string
            label      = optional(string)
            metric_stat = optional(object({
              metric = object({
                dimension = optional(list(object({
                  name  = string
                  value = string
                })))
                metric_name = optional(string)
                namespace   = optional(string)
              })
              stat = string
              unit = optional(string)
            }))
            return_data = optional(bool)
          }))
        }))
        customized_scaling_metric_specification = optional(object({
          metric_data_query = list(object({
            expression = optional(string)
            id         = string
            label      = optional(string)
            metric_stat = optional(object({
              metric = object({
                dimension = optional(list(object({
                  name  = string
                  value = string
                })))
                metric_name = optional(string)
                namespace   = optional(string)
              })
              stat = string
              unit = optional(string)
            }))
            return_data = optional(bool)
          }))
        }))
        predefined_load_metric_specification = optional(object({
          predefined_metric_type = string
          resource_label         = optional(string)
        }))
        predefined_metric_pair_specification = optional(object({
          predefined_metric_type = string
          resource_label         = optional(string)
        }))
        predefined_scaling_metric_specification = optional(object({
          predefined_metric_type = string
          resource_label         = optional(string)
        }))
        target_value = number
      }))
      mode                   = optional(string)
      scheduling_buffer_time = optional(number)
    }))
    step_scaling_policy_configuration = optional(object({
      adjustment_type          = optional(string)
      cooldown                 = optional(number)
      metric_aggregation_type  = optional(string)
      min_adjustment_magnitude = optional(number)
      step_adjustment = optional(list(object({
        metric_interval_lower_bound = optional(string)
        metric_interval_upper_bound = optional(string)
        scaling_adjustment          = number
      })))
    }))
    target_tracking_scaling_policy_configuration = optional(object({
      customized_metric_specification = optional(object({
        dimensions = optional(list(object({
          name  = string
          value = string
        })))
        metric_name = optional(string)
        metrics = optional(list(object({
          expression = optional(string)
          id         = string
          label      = optional(string)
          metric_stat = optional(object({
            metric = object({
              dimensions = optional(list(object({
                name  = string
                value = string
              })))
              metric_name = string
              namespace   = string
            })
            stat = string
            unit = optional(string)
          }))
          return_data = optional(bool)
        })))
        namespace = optional(string)
        statistic = optional(string)
        unit      = optional(string)
      }))
      disable_scale_in = optional(bool)
      predefined_metric_specification = optional(object({
        predefined_metric_type = string
        resource_label         = optional(string)
      }))
      scale_in_cooldown  = optional(number, 300)
      scale_out_cooldown = optional(number, 60)
      target_value       = optional(number, 75)
    }))
  }))
  default = {
    "cpu" : {
      "policy_type" : "TargetTrackingScaling",
      "target_tracking_scaling_policy_configuration" : {
        "predefined_metric_specification" : {
          "predefined_metric_type" : "ECSServiceAverageCPUUtilization"
        }
      }
    },
    "memory" : {
      "policy_type" : "TargetTrackingScaling",
      "target_tracking_scaling_policy_configuration" : {
        "predefined_metric_specification" : {
          "predefined_metric_type" : "ECSServiceAverageMemoryUtilization"
        }
      }
    }
  }
}

variable "autoscaling_scheduled_actions" {
  description = "Map of autoscaling scheduled actions to create for the service"
  type = map(object({
    name         = optional(string)
    min_capacity = number
    max_capacity = number
    schedule     = string
    start_time   = optional(string)
    end_time     = optional(string)
    timezone     = optional(string)
  }))
  default = null
}

variable "autoscaling_suspended_state" {
  description = "Configuration block that specifies whether the scaling activities for the service are in a suspended state"
  type = object({
    dynamic_scaling_in_suspended  = optional(bool, false)
    dynamic_scaling_out_suspended = optional(bool, false)
    scheduled_scaling_suspended   = optional(bool, false)
  })
  default = null
}

variable "availability_zone_rebalancing" {
  description = "ECS automatically redistributes tasks within a service across Availability Zones (AZs) to mitigate the risk of impaired application availability due to underlying infrastructure failures and task lifecycle activities. The valid values are `ENABLED` and `DISABLED`. Defaults to `DISABLED`"
  type        = string
  default     = null
}
