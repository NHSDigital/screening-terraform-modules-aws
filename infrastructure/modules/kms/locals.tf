locals {
  name = format("alias/%v", module.this.id)
  aliases = length(var.aliases) > 0 ? var.aliases : [local.name]
}
