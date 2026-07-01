locals {
  log_group_name  = module.this.id
  log_stream_name = format("%s-stream", module.this.id)
}
