locals {
  create_log_group  = var.create == "LOG_GROUP_ONLY" || var.create == "LOG_GROUP_AND_LOG_STREAM"
  create_log_stream = var.create == "LOG_GROUP_AND_LOG_STREAM"

  log_group_name  = module.this.id
  log_stream_name = format("%s-stream", module.this.id)
}
