#################
#  SNS wrapper  #
#################

data "aws_partition" "current" {}

module "sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.0"

  name                        = local.topic_name
  fifo_topic                  = false
  content_based_deduplication = false

  create_topic_policy         = true
  enable_default_topic_policy = true

  # Preserve legacy publish rules that existing stacks depend on.
  # TODO: Refine these to be more restrictive, e.g. removing defaults and requiring user input, once all stacks have migrated to the new module version.
  topic_policy_statements = {
    eventbridge_publish = {
      sid     = "AllowEventBridgePublish"
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }]
    }

    elasticache_publish = {
      sid     = "AllowElastiCachePublish"
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["elasticache.amazonaws.com"]
      }]
    }

    backup_publish = {
      sid     = "AllowBackupPublish"
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["backup.amazonaws.com"]
      }]
    }

    ecs_publish = {
      sid     = "AllowAllECSTasksToPublish"
      actions = ["sns:Publish"]
      principals = [{
        type        = "AWS"
        identifiers = ["*"]
      }]
      condition = [{
        test     = "StringLike"
        variable = "aws:PrincipalArn"
        values = [
          "arn:${data.aws_partition.current.partition}:iam::${var.aws_account_id}:role/${local.topic_name}-ecs*"
        ]
      }]
    }
  }

  subscriptions = var.subscriptions

  tags = module.this.tags
}
