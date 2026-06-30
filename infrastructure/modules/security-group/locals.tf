locals {
  # Security group name is derived from context. The community module receives
  # module.this.id directly so that context-driven label ordering is
  # preserved without an intermediate local in the common case.
  security_group_name = var.security_group_name != "" ? var.security_group_name : module.this.id
}
