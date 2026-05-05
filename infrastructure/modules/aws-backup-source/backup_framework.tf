resource "aws_backup_framework" "rds" {
  count = var.backup_plan_config_rds.enable ? 1 : 0
  # must be underscores instead of dashes
  name        = replace("${var.name_prefix}-rds-framework", "-", "_")
  description = "${var.project_name} RDS Backup Framework"

  # Evaluates if resources are protected by a backup plan.
  control {
    name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"

    scope {
      compliance_resource_types = var.backup_plan_config_rds.compliance_resource_types
      tags = {
        (var.backup_plan_config_rds.selection_tag) = (var.backup_plan_config_rds.selection_tag_value)
      }
    }
  }

  # Evaluates if resources have at least one recovery point created within the past 1 day.
  control {
    name = "BACKUP_LAST_RECOVERY_POINT_CREATED"

    input_parameter {
      name  = "recoveryPointAgeUnit"
      value = "days"
    }

    input_parameter {
      name  = "recoveryPointAgeValue"
      value = "1"
    }

    scope {
      compliance_resource_types = var.backup_plan_config_rds.compliance_resource_types
      tags = {
        (var.backup_plan_config_rds.selection_tag) = (var.backup_plan_config_rds.selection_tag_value)
      }
    }
  }

}
