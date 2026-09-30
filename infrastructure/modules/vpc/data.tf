# Skipped when disabled or when an explicit AZ list is supplied, avoiding an unneeded API call.
data "aws_availability_zones" "available" {
  count = module.this.enabled && length(coalesce(var.availability_zones, [])) == 0 ? 1 : 0

  state = "available"
}
