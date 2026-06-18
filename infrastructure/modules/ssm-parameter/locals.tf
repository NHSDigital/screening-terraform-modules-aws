locals {
  # if the name is a path (contains a slash),
  # then it must be fully qualified (start with a slash)
  name = (
    !strcontains(module.this.name, "/") || startswith(module.this.name, "/")
    ? module.this.name
    : "/${module.this.name}"
  )
}
