################################################################
# Route53-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# `context.tf` via `module.this`.
################################################################

variable "hosted_zones" {
  description = <<-EOT
    Map of hosted zones to create or adopt.

    Each key is a logical identifier used only in Terraform state and outputs.
    Each value forwards to the upstream `terraform-aws-modules/route53/aws`
    root module.

    `name` is the DNS zone name (for example `example.internal` or
    `example.nhs.uk`) and is required.
  EOT

  type = map(object({
    name                        = string
    create                      = optional(bool, true)
    create_zone                 = optional(bool, true)
    private_zone                = optional(bool, false)
    vpc_id                      = optional(string)
    comment                     = optional(string)
    delegation_set_id           = optional(string)
    force_destroy               = optional(bool)
    enable_accelerated_recovery = optional(bool)
    ignore_vpc                  = optional(bool, false)
    vpc = optional(map(object({
      vpc_id     = string
      vpc_region = optional(string)
    })))
    vpc_association_authorizations = optional(map(object({
      vpc_id     = string
      vpc_region = optional(string)
    })))
    enable_dnssec               = optional(bool, false)
    create_dnssec_kms_key       = optional(bool, true)
    dnssec_kms_key_arn          = optional(string)
    dnssec_kms_key_description  = optional(string)
    dnssec_kms_key_aliases      = optional(list(string), [])
    dnssec_kms_key_tags         = optional(map(string), {})
    dnssec_key_signing_key_name = optional(string)
    records                     = optional(any, {})
    tags                        = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  }))
  default = {}
}

variable "resolver_endpoints" {
  description = <<-EOT
    Map of Route53 Resolver endpoints to create.

    Each key is a logical identifier used in Terraform state and outputs.
    Names default to a context-derived value when `name` is omitted.
  EOT

  type = map(object({
    create    = optional(bool, true)
    region    = optional(string)
    name      = optional(string)
    direction = optional(string, "INBOUND")
    type      = optional(string)
    protocols = optional(list(string), ["Do53"])
    ip_address = optional(list(object({
      ip        = optional(string)
      ipv6      = optional(string)
      subnet_id = string
    })), [])
    security_group_ids             = optional(list(string), [])
    create_security_group          = optional(bool, true)
    security_group_name            = optional(string)
    security_group_use_name_prefix = optional(bool, false)
    security_group_description     = optional(string)
    vpc_id                         = optional(string)
    security_group_ingress_rules = optional(map(object({
      name                         = optional(string)
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      description                  = optional(string)
      prefix_list_id               = optional(string)
      referenced_security_group_id = optional(string)
      tags                         = optional(map(string), {})
    })), {})
    security_group_egress_rules = optional(map(object({
      name                         = optional(string)
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      description                  = optional(string)
      prefix_list_id               = optional(string)
      referenced_security_group_id = optional(string)
      tags                         = optional(map(string), {})
    })), {})
    security_group_tags = optional(map(string), {})
    rules = optional(map(object({
      domain_name = string
      name        = optional(string)
      rule_type   = string
      tags        = optional(map(string), {})
      target_ip = optional(list(object({
        ip       = string
        ipv6     = optional(string)
        port     = optional(number)
        protocol = optional(string)
      })))
      vpc_id = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, ep in var.resolver_endpoints :
      alltrue([
        for p in ep.protocols : contains(["Do53", "DoH", "DoH-FIPS"], p)
      ])
    ])
    error_message = "Each protocol value must be one of: Do53, DoH, DoH-FIPS. An empty list defaults to Do53."
  }
}

variable "resolver_firewall_rule_groups" {
  description = <<-EOT
    Map of Route53 Resolver DNS Firewall rule groups to create.

    Each rule can either create a dedicated firewall domain list via `domains`
    or reference an existing one via `firewall_domain_list_id`.
  EOT

  type = map(object({
    create = optional(bool, true)
    region = optional(string)
    name   = optional(string)
    ram_resource_associations = optional(map(object({
      resource_share_arn = string
    })), {})
    vpc_ids  = optional(map(string), {})
    priority = optional(number, 100)
    rules = optional(map(object({
      name                               = optional(string)
      domains                            = optional(list(string))
      action                             = string
      block_override_dns_type            = optional(string)
      block_override_domain              = optional(string)
      block_override_ttl                 = optional(number)
      block_response                     = optional(string)
      firewall_domain_list_id            = optional(string)
      firewall_domain_redirection_action = optional(string)
      priority                           = number
      q_type                             = optional(string)
      tags                               = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}
