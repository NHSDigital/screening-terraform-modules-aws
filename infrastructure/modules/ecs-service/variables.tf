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

variable "capacity_provider_strategy" {
  description = "Capacity provider strategies to use for the service. Can be one or more"
  type = map(object({
    base              = optional(number)
    capacity_provider = string
    weight            = optional(number)
  }))
  default = null
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster where the resources will be provisioned"
  type        = string
  default     = ""
}

variable "container_definitions" {
  description = "A map of valid container definitions <http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html>. Please note that you should only provide values that are part of the container definition document"
  type = map(object({
    create                  = optional(bool, true)
    operating_system_family = optional(string)
    tags                    = optional(map(string)) # Container definition
    command                 = optional(list(string))
    cpu                     = optional(number)
    credentialSpecs         = optional(list(string))
    dependsOn = optional(list(object({
      condition     = string
      containerName = string
    })))
    disableNetworking     = optional(bool)
    dnsSearchDomains      = optional(list(string))
    dnsServers            = optional(list(string))
    dockerLabels          = optional(map(string))
    dockerSecurityOptions = optional(list(string))
    # DAVEH: following line was comment to preceeding line
    enable_execute_command = optional(bool, false) # Set in standalone variable
    entrypoint             = optional(list(string))
    environment = optional(list(object({
      name  = string
      value = string
    })))
    environmentFiles = optional(list(object({
      type  = string
      value = string
    })))
    essential = optional(bool)
    extraHosts = optional(list(object({
      hostname  = string
      ipAddress = string
    })))
    firelensConfiguration = optional(object({
      options = optional(map(string))
      type    = optional(string)
    }))
    healthCheck = optional(object({
      command     = optional(list(string), [])
      interval    = optional(number, 30)
      retries     = optional(number, 3)
      startPeriod = optional(number)
      timeout     = optional(number, 5)
    }))
    hostname    = optional(string)
    image       = optional(string)
    interactive = optional(bool)
    links       = optional(list(string))
    linuxParameters = optional(object({
      capabilities = optional(object({
        add  = optional(list(string))
        drop = optional(list(string))
      }))
      devices = optional(list(object({
        containerPath = optional(string)
        hostPath      = optional(string)
        permissions   = optional(list(string))
      })))
      initProcessEnabled = optional(bool)
      maxSwap            = optional(number)
      sharedMemorySize   = optional(number)
      swappiness         = optional(number)
      tmpfs = optional(list(object({
        containerPath = string
        mountOptions  = optional(list(string))
        size          = number
      })))
    }))
    logConfiguration = optional(object({
      logDriver = optional(string)
      options   = optional(map(string))
      secretOptions = optional(list(object({
        name      = string
        valueFrom = string
      })))
    }))
    memory            = optional(number)
    memoryReservation = optional(number)
    mountPoints = optional(list(object({
      containerPath = optional(string)
      readOnly      = optional(bool)
      sourceVolume  = optional(string)
    })))
    name = optional(string)
    portMappings = optional(list(object({
      appProtocol        = optional(string)
      containerPort      = optional(number)
      containerPortRange = optional(string)
      hostPort           = optional(number)
      name               = optional(string)
      protocol           = optional(string)
    })))
    privileged             = optional(bool)
    pseudoTerminal         = optional(bool)
    readonlyRootFilesystem = optional(bool)
    repositoryCredentials = optional(object({
      credentialsParameter = optional(string)
    }))
    resourceRequirements = optional(list(object({
      type  = string
      value = string
    })))
    restartPolicy = optional(object({
      enabled              = optional(bool)
      ignoredExitCodes     = optional(list(number))
      restartAttemptPeriod = optional(number)
    }))
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })))
    startTimeout = optional(number, 30)
    stopTimeout  = optional(number, 120)
    systemControls = optional(list(object({
      namespace = optional(string)
      value     = optional(string)
    })))
    ulimits = optional(list(object({
      hardLimit = number
      name      = string
      softLimit = number
    })))
    user               = optional(string)
    versionConsistency = optional(string)
    volumesFrom = optional(list(object({
      readOnly        = optional(bool)
      sourceContainer = optional(string)
    })))
    workingDirectory = optional(string)
    # Cloudwatch Log Group
    service                                = optional(string)
    enable_cloudwatch_logging              = optional(bool)
    create_cloudwatch_log_group            = optional(bool)
    cloudwatch_log_group_name              = optional(string)
    cloudwatch_log_group_use_name_prefix   = optional(bool)
    cloudwatch_log_group_class             = optional(string)
    cloudwatch_log_group_retention_in_days = optional(number)
    cloudwatch_log_group_kms_key_id        = optional(string)
  }))
  default = {}
}

variable "cpu" {
  description = "Number of cpu units used by the task. If the `requires_compatibilities` is `FARGATE` this field is required"
  type        = number
  default     = 1024
}

variable "create_iam_role" {
  description = "Determines whether the ECS service IAM role should be created"
  type        = bool
  default     = true
}

variable "create_infrastructure_iam_role" {
  description = "Determines whether the ECS infrastructure IAM role should be created"
  type        = bool
  default     = true
}

variable "create_security_group" {
  description = "Determines if a security group is created"
  type        = bool
  default     = true
}

variable "create_service" {
  description = "Determines whether service resource will be created (set to `false` in case you want to create task definition only)"
  type        = bool
  default     = true
}

variable "create_task_definition" {
  description = "Determines whether to create a task definition or use existing/provided"
  type        = bool
  default     = true
}

variable "create_task_exec_iam_role" {
  description = "Determines whether the ECS task definition IAM role should be created"
  type        = bool
  default     = true
}

variable "create_task_exec_policy" {
  description = "Determines whether the ECS task definition IAM policy should be created. This includes permissions included in AmazonECSTaskExecutionRolePolicy as well as access to secrets and SSM parameters"
  type        = bool
  default     = true
}

variable "create_tasks_iam_role" {
  description = "Determines whether the ECS tasks IAM role should be created"
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker" {
  description = "Configuration block for deployment circuit breaker"
  type = object({
    enable   = bool
    rollback = bool
  })
  default = null
}

variable "deployment_configuration" {
  description = "Configuration block for deployment settings"
  type = object({
    strategy             = optional(string)
    bake_time_in_minutes = optional(string)
    canary_configuration = optional(object({
      canary_bake_time_in_minutes = optional(string)
      canary_percent              = optional(string)
    }))
    linear_configuration = optional(object({
      step_bake_time_in_minutes = optional(string)
      step_percent              = optional(string)
    }))
    lifecycle_hook = optional(map(object({
      hook_target_arn  = string
      role_arn         = optional(string)
      lifecycle_stages = list(string)
      hook_details     = optional(string)
    })))
  })
  default = null
}

variable "deployment_controller" {
  description = "Configuration block for deployment controller configuration"
  type = object({
    type = optional(string)
  })
  default = null
}

variable "deployment_maximum_percent" {
  description = "Upper limit (as a percentage of the service's `desired_count`) of the number of running tasks that can be running in a service during a deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit (as a percentage of the service's `desired_count`) of the number of running tasks that must remain running and healthy in a service during a deployment"
  type        = number
  default     = 66
}

variable "desired_count" {
  description = "Number of instances of the task definition to place and keep running"
  type        = number
  default     = 1
}

variable "enable_autoscaling" {
  description = "Determines whether to enable autoscaling for the service"
  type        = bool
  default     = true
}

variable "enable_ecs_managed_tags" {
  description = "Specifies whether to enable Amazon ECS managed tags for the tasks within the service"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service"
  type        = bool
  default     = false
}

variable "enable_fault_injection" {
  description = "Enables fault injection and allows for fault injection requests to be accepted from the task's containers. Default is `false`"
  type        = bool
  default     = null
}

variable "ephemeral_storage" {
  description = "The amount of ephemeral storage to allocate for the task. This parameter is used to expand the total amount of ephemeral storage available, beyond the default amount, for tasks hosted on AWS Fargate"
  type = object({
    size_in_gib = number
  })
  default = null
}

variable "external_id" {
  description = "The external ID associated with the task set"
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Enable to delete a service even if it wasn't scaled down to zero tasks. It's only necessary to use this if the service uses the `REPLICA` scheduling strategy"
  type        = bool
  default     = null
}

variable "force_new_deployment" {
  description = "Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination, roll Fargate tasks onto a newer platform version, or immediately deploy `ordered_placement_strategy` and `placement_constraints` updates"
  type        = bool
  default     = true
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers"
  type        = number
  default     = null
}

variable "iam_role_arn" {
  description = "Existing IAM role ARN"
  type        = string
  default     = null
}

variable "iam_role_description" {
  description = "Description of the role"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "iam_role_path" {
  description = "IAM role path"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "iam_role_statements" {
  description = "A map of IAM policy statements <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement> for custom permission usage"
  type = list(object({
    sid           = optional(string)
    actions       = optional(list(string))
    not_actions   = optional(list(string))
    effect        = optional(string)
    resources     = optional(list(string))
    not_resources = optional(list(string))
    principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })))
    not_principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })))
    condition = optional(list(object({
      test     = string
      values   = list(string)
      variable = string
    })))
  }))
  default = null
}

variable "iam_role_tags" {
  description = "A map of additional tags to add to the IAM role created"
  type        = map(string)
  default     = {}
}

variable "iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name (`iam_role_name`) is used as a prefix"
  type        = bool
  default     = true
}
