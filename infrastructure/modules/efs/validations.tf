################################################################
# Input validation
#
# Validates cross-variable constraints that cannot be expressed
# through individual variable validation blocks:
#
#   * throughput_mode = "provisioned" requires provisioned_throughput_in_mibps
#   * replication_configuration must have mount_targets defined
#   * access_points must have mount_targets defined
#   * lifecycle_policy keys must be valid EFS policy keys
#   * replication_overwrite must be "DISABLED" or "ENABLED"
#   * access_point permissions_mode must be valid octal (3-4 digits)
#   * availability_zone_name (one-zone) requires exactly one mount target
################################################################

resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(var.throughput_mode == "provisioned" && var.provisioned_throughput_in_mibps == null)
      error_message = "throughput_mode = 'provisioned' requires provisioned_throughput_in_mibps to be set."
    }
    precondition {
      condition     = !(length(var.replication_configuration) > 0 && length(var.mount_targets) == 0)
      error_message = "replication_configuration requires at least one mount target to be configured."
    }
    precondition {
      condition     = !(length(var.access_points) > 0 && length(var.mount_targets) == 0)
      error_message = "access_points requires at least one mount target to be configured."
    }
    precondition {
      condition = var.lifecycle_policy == null ? true : (
        alltrue([
          for key in keys(var.lifecycle_policy) : contains([
            "transition_to_ia",
            "transition_to_primary_storage_class"
          ], key)
        ])
      )
      error_message = "lifecycle_policy keys must be one of: transition_to_ia, transition_to_primary_storage_class."
    }
    precondition {
      condition     = var.protection.replication_overwrite == null ? true : contains(["DISABLED", "ENABLED"], var.protection.replication_overwrite)
      error_message = "protection.replication_overwrite must be 'DISABLED' or 'ENABLED'."
    }
    precondition {
      condition = alltrue([
        for ap_key, ap in var.access_points : can(regex("^[0-7]{3,4}$", ap.permissions_mode))
      ])
      error_message = "access_point permissions_mode must be valid octal notation (e.g., '755', '700')."
    }
    precondition {
      condition     = !(var.availability_zone_name != null && length(var.mount_targets) != 1)
      error_message = "availability_zone_name (one-zone storage) requires exactly one mount target; found ${length(var.mount_targets)}."
    }
  }
}
