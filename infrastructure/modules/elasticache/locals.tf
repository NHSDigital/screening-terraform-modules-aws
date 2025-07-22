locals {
  replication_group_id = "${var.name_prefix}${var.name}"
  #for engine-log prefix https://docs.aws.amazon.com/step-functions/latest/dg/bp-cwl.html
  cw_redis_engine_log  = "/aws/vendedlogs/${var.name_prefix}-redis-engine-logs"
  cw_redis_slow_log    = "/aws/vendedlogs/${var.name_prefix}-redis-slow-logs"
  subnet_group         = "${var.name_prefix}${var.name}-subnet-group"
  sg_name              = "${var.name_prefix}${var.name}-sg"
  parameter_group_name = var.name_prefix
}
