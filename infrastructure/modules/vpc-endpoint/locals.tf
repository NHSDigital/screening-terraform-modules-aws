################################################################
# Local values
#
# Merges per-endpoint configuration with module defaults (var.security_group_id).
# Interface endpoints use either their specified security_group_ids or the default.
################################################################

locals {
  # Intelligently merge endpoints with module defaults (var.security_group_id, var.subnet_ids)
  # Precedence: per-endpoint values > module defaults > upstream defaults
  # This enables a caller to set defaults while allowing per-endpoint overrides.
  endpoints_merged = {
    for k, v in var.endpoints :
    k => merge(
      v,
      # Merge security_group_ids: per-endpoint > default
      # Only add security_group_ids if:
      # 1. Endpoint doesn't already specify them AND
      # 2. var.security_group_id is set AND
      # 3. Endpoint is Interface type (or unspecified, defaulting to Interface)
      try(v.security_group_ids, null) == null &&
      var.security_group_id != null &&
      try(v.service_type, "Interface") == "Interface" ?
      { security_group_ids = [var.security_group_id] } :
      {},
      # Merge subnet_ids: per-endpoint > default
      # Only add subnet_ids if:
      # 1. Endpoint doesn't already specify them AND
      # 2. var.subnet_ids is set
      try(v.subnet_ids, null) == null &&
      length(var.subnet_ids) > 0 ?
      { subnet_ids = var.subnet_ids } :
      {}
    )
  }
}
