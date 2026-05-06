######################
#  Elasticache
######################

resource "aws_elasticache_replication_group" "elasticache_replication_group" {
  replication_group_id       = local.replication_group_id
  description                = var.replication_group_description
  node_type                  = var.node_type
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  port                       = var.elasticache_port
  apply_immediately          = var.apply_immediately
  parameter_group_name       = aws_elasticache_parameter_group.bss_param_group_redis7.name
  automatic_failover_enabled = var.auto_failover_enabled
  auto_minor_version_upgrade = true
  maintenance_window         = "Mon:00:00-Mon:03:00"
  snapshot_window            = "04:00-08:00"
  notification_topic_arn     = var.notification_topic_arn
  subnet_group_name          = aws_elasticache_subnet_group.cache_subnet_group.name
  security_group_ids         = [aws_security_group.cache_sg.id]
  engine_version             = var.engine_version
  cluster_mode               = "enabled"
  replicas_per_node_group    = var.replicas_per_node_group
  num_node_groups            = var.number_of_shards

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }
  depends_on = [aws_cloudwatch_log_group.redis_engine_log, aws_cloudwatch_log_group.redis_slow_log]
}

resource "aws_iam_service_linked_role" "elasticache" {
  count            = var.create_elasticache_service_role ? 1 : 0
  aws_service_name = "elasticache.amazonaws.com"
}

# to allow referencing the existing service linked role if not created
data "aws_iam_role" "elasticache" {
  name       = "AWSServiceRoleForElastiCache"
  depends_on = [aws_iam_service_linked_role.elasticache]
}

resource "aws_elasticache_parameter_group" "bss_param_group_redis7" {
  name   = "${local.parameter_group_name}-redis7"
  family = "redis7"

  parameter {
    name  = "cluster-enabled"
    value = "yes"
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [data.aws_iam_role.elasticache]
}

######################
#  Networking
######################

resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name        = local.subnet_group
  description = "Subnet group for Elasticache"
  subnet_ids  = var.subnet_ids
  depends_on  = [data.aws_iam_role.elasticache]
}

resource "aws_security_group" "cache_sg" {
  name        = local.sg_name
  description = "Allow connection by appointed cache clients"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ecs-inbound" {
  description                  = "Allows inbound connection from ECS cluster"
  security_group_id            = aws_security_group.cache_sg.id
  referenced_security_group_id = var.ecs_sg_id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  tags = {
    "Name" : "${var.name_prefix}-ecs"
  }
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name = local.cw_redis_engine_log
  #kms_key_id        = data.aws_kms_key.kms_key.arn
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name = local.cw_redis_slow_log
  #kms_key_id        = data.aws_kms_key.kms_key.arn
  retention_in_days = 365
}
