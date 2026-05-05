module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  create_bus  = false
  create_role = false

  rules = {
    "${var.name_prefix}-backup-start-cross-account-copy-job" = {
      description = "Identify when a new recovery point is created in the intermediary vault"
      event_pattern = jsonencode(
        {
          "source" : ["aws.backup"],
          "account" : ["${data.aws_caller_identity.current.account_id}"],
          "region" : ["eu-west-2"],
          "detail" : {
            "eventName" : ["RecoveryPointCreated"],
            "serviceEventDetails" : {
              "backupVaultName" : [{ "wildcard" : "*-intermediary-vault" }]
            }
          }
        }
      )
      enabled = true
    }
  }

  targets = {
    "${var.name_prefix}-backup-start-cross-account-copy-job" = [
      {
        name = "start-cross-account-copy-job"
        arn  = "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.current.account_id}:function:${var.name_prefix}-backup-start-cross-account-copy-job"
      }
    ]
  }
}
