locals {
  # Service name is derived from context. The community module receives
  # module.this.name directly so that context-driven label ordering is
  # preserved without an intermediate local in the common case.
  service_name = var.service_name != null ? var.service_name : module.this.name
}
