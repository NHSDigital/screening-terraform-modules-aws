# DAVEH

variable "capacity_providers" {
  type = map(object({
    auto_scaling_group_provider = optional(object({
      auto_scaling_group_arn = string
      managed_draining = optional(string, "ENABLED")
      managed_scaling = optional(object({
        instance_warmup_period = optional(number)
        maximum_scaling_step_size = optional(number)
        minimum_scaling_step_size = optional(number)
        status = optional(string)
        target_capacity = optional(number)
      }))
      managed_termination_protection = optional(string)
    }))
    managed_instances_provider = optional(object({
      infrastructure_role_arn = optional(string)
      instance_launch_template = object({
        capacity_option_type = optional(string)
        ec2_instance_profile_arn = optional(string)
        instance_requirements = optional(object({
          accelerator_count = optional(object({
            max = optional(number)
            min = optional(number)
          }))
          accelerator_manufacturers = optional(list(string))
          accelerator_names = optional(list(string))
          accelerator_total_memory_mib = optional(object({
            max = optional(number)
            min = optional(number)
          }))
          accelerator_types = optional(list(string))
          allowed_instance_types = optional(list(string))
          bare_metal = optional(string)
          baseline_ebs_bandwidth_mbps = optional(object({
            max = optional(number)
            min = optional(number)
          }))
          burstable_performance = optional(string)
          cpu_manufacturers = optional(list(string))
          excluded_instance_types = optional(list(string))
          instance_generations = optional(list(string))
          local_storage = optional(string)
          local_storage_types = optional(list(string))
          max_spot_price_as_percentage_of_optimal_on_demand_price = optional(number)
          memory_gib_per_vcpu = optional(object({ max = optional(number) min = optional(number) }))
          memory_mib = optional(object({ max = optional(number) min = optional(number) }))
          network_bandwidth_gbps = optional(object({ max = optional(number) min = optional(number) }))
          network_interface_count = optional(object({ max = optional(number) min = optional(number) }))
          on_demand_max_price_percentage_over_lowest_price = optional(number)
          require_hibernate_support = optional(bool)
          spot_max_price_percentage_over_lowest_price = optional(number)
          total_local_storage_gb = optional(object({ max = optional(number) min = optional(number) }))
          vcpu_count = optional(object({ max = optional(number) min = optional(number) }))
        }))
        monitoring = optional(string)
        network_configuration = optional(object({ security_groups = optional(list(string), []) subnets = list(string) }))
        storage_configuration = optional(object({ storage_size_gib = number }))
      })
      propagate_tags = optional(string, "CAPACITY_PROVIDER")
    }))
    name = optional(string) # Will fall back to use map key if not set
    tags = optional(map(string), {})
  }))
  default = null
  description = "Map of capacity provider definitions to create"
}
