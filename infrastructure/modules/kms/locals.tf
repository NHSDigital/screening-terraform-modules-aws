locals {
  aliases = length(var.aliases) > 0 ? var.aliases : [module.this.id]
}
