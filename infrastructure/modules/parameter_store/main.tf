locals {
  standard_cognito_users = jsonencode([
    {
      "uuid" : "100000000001",
      "bss_username" : "BSS_NO_RBAC",
      "rbac_role" : "[]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "100000000002",
      "bss_username" : "BSS_NO_ID_ASSURANCE",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 0
    },
    {
      "uuid" : "555033739104",
      "bss_username" : "BSS_USER1",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "555033740107",
      "bss_username" : "BSS_USER2",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "555033741108",
      "bss_username" : "BSS_USER3",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "555033742109",
      "bss_username" : "BSS_USER4",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "555033743100",
      "bss_username" : "BSS_USER5",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "555033744101",
      "bss_username" : "BSS_USER6",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "555033745102",
      "bss_username" : "BSS_USER7",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000001",
      "bss_username" : "BSS_PERF1",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000002",
      "bss_username" : "BSS_PERF2",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000003",
      "bss_username" : "BSS_PERF3",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000004",
      "bss_username" : "BSS_PERF4",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000005",
      "bss_username" : "BSS_PERF5",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000006",
      "bss_username" : "BSS_PERF6",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000007",
      "bss_username" : "BSS_PERF7",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000008",
      "bss_username" : "BSS_PERF8",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000009",
      "bss_username" : "BSS_PERF9",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000010",
      "bss_username" : "BSS_PERF10",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000011",
      "bss_username" : "BSS_PERF11",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000012",
      "bss_username" : "BSS_PERF12",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000013",
      "bss_username" : "BSS_PERF13",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000014",
      "bss_username" : "BSS_PERF14",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000015",
      "bss_username" : "BSS_PERF15",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000016",
      "bss_username" : "BSS_PERF16",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000017",
      "bss_username" : "BSS_PERF17",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000018",
      "bss_username" : "BSS_PERF18",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000019",
      "bss_username" : "BSS_PERF19",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000020",
      "bss_username" : "BSS_PERF20",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    }
    ]
  )

  training_cognito_users = jsonencode([
    {
      "uuid" : "000000000001",
      "bss_username" : "BSS_UAT1",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000002",
      "bss_username" : "BSS_UAT2",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000003",
      "bss_username" : "BSS_UAT3",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000004",
      "bss_username" : "BSS_UAT4",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000005",
      "bss_username" : "BSS_UAT5",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000006",
      "bss_username" : "BSS_UAT6",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000007",
      "bss_username" : "BSS_UAT7",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000008",
      "bss_username" : "BSS_UAT8",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000009",
      "bss_username" : "BSS_UAT9",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "0000000000010",
      "bss_username" : "BSS_UAT10",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000011",
      "bss_username" : "BSS_UAT11",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000012",
      "bss_username" : "BSS_UAT12",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000013",
      "bss_username" : "BSS_UAT13",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000014",
      "bss_username" : "BSS_UAT14",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000015",
      "bss_username" : "BSS_READ1",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000016",
      "bss_username" : "BSS_READ2",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000017",
      "bss_username" : "BSS_READ3",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000018",
      "bss_username" : "BSS_READ4",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000019",
      "bss_username" : "BSS_READ5",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000020",
      "bss_username" : "BSS_READ6",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000021",
      "bss_username" : "JILJOB",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000022",
      "bss_username" : "SUZWRI",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    },
    {
      "uuid" : "000000000023",
      "bss_username" : "TOMMYS",
      "rbac_role" : "[{activities=[BS-Select], activity_codes=[B1808]}]",
      "id_assurance_level" : 3
    }
    ]
  )
}

resource "aws_ssm_parameter" "cognito_users" {
  # don't deploy cognito users in prod or col as not used
  count = var.environment != "prod" && var.environment != "col" ? 1 : 0
  name  = "/${var.name_prefix}/cognito/users"
  type  = "String"
  value = var.environment == "training" ? local.training_cognito_users : local.standard_cognito_users
}

# For cloudwatch agent configuration for ECS tasks
resource "aws_ssm_parameter" "ecs_cw_agent_config_parameter" {
  count       = var.enable_cloudwatch_agent ? 1 : 0
  name        = "/${var.name_prefix}/ecs-cw-agent-config"
  description = "CloudWatch Agent configuration for ECS tasks in the ${var.name_prefix} environment"
  type        = "String"
  value       = var.cloudwatch_agent_config_json
}
