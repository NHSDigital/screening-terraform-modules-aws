locals {
  env_map = {
    prod = {
      fqdn    = "en.bs-select.nhs.uk"
      env    = "prod"
    },
    col = {
      fqdn    = "col.bs-select.nhs.uk"
      env     = "col"
    },
    preprod = {
      fqdn    = "training.bs-select.nhs.uk"
      env     = "training"
    }
    integration = {
      fqdn    = "integration.bs-select.nhs.uk"
      env     = "integration"
    }
  }
  fqdn    = local.env_map[var.environment].fqdn
  env     = local.env_map[var.environment].env
}
