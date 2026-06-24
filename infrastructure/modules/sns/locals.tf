locals {
  # Use the caller-supplied topic name if provided; otherwise fall back
  # to the auto-generated context ID. The caller controls the generated
  # name by setting context labels: service, environment, stack, name, etc.
  topic_name = var.topic_name != null ? var.topic_name : module.this.id

  # ECS role prefix for the publish policy condition. Defaults to the topic
  # name (matching the legacy module's use of name_prefix). Callers whose
  # ECS roles use a different prefix can override via var.ecs_role_prefix.
  ecs_role_prefix = var.ecs_role_prefix != null ? var.ecs_role_prefix : local.topic_name
}
