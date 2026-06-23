output "hosted_zone_ids" {
  description = "Map of hosted zone key -> Route53 hosted zone ID."
  value       = { for key, zone in module.hosted_zones : key => zone.id }
}

output "hosted_zone_arns" {
  description = "Map of hosted zone key -> Route53 hosted zone ARN."
  value       = { for key, zone in module.hosted_zones : key => zone.arn }
}

output "hosted_zone_names" {
  description = "Map of hosted zone key -> Route53 hosted zone name."
  value       = { for key, zone in module.hosted_zones : key => zone.name }
}

output "hosted_zone_name_servers" {
  description = "Map of hosted zone key -> authoritative name servers."
  value       = { for key, zone in module.hosted_zones : key => zone.name_servers }
}

output "hosted_zone_records" {
  description = "Map of hosted zone key -> records created in the zone."
  value       = { for key, zone in module.hosted_zones : key => zone.records }
}

output "resolver_endpoint_ids" {
  description = "Map of resolver endpoint key -> endpoint ID."
  value       = { for key, endpoint in module.resolver_endpoints : key => endpoint.id }
}

output "resolver_endpoint_arns" {
  description = "Map of resolver endpoint key -> endpoint ARN."
  value       = { for key, endpoint in module.resolver_endpoints : key => endpoint.arn }
}

output "resolver_endpoint_host_vpc_ids" {
  description = "Map of resolver endpoint key -> host VPC ID."
  value       = { for key, endpoint in module.resolver_endpoints : key => endpoint.host_vpc_id }
}

output "resolver_endpoint_security_group_ids" {
  description = "Map of resolver endpoint key -> attached security group IDs."
  value       = { for key, endpoint in module.resolver_endpoints : key => endpoint.security_group_ids }
}

output "resolver_endpoint_security_group_arns" {
  description = "Map of resolver endpoint key -> created security group ARN."
  value       = { for key, endpoint in module.resolver_endpoints : key => endpoint.security_group_arn }
}

output "resolver_endpoint_created_security_group_ids" {
  description = "Map of resolver endpoint key -> created security group ID."
  value       = { for key, endpoint in module.resolver_endpoints : key => endpoint.security_group_id }
}

output "resolver_endpoint_ip_addresses" {
  description = "Map of resolver endpoint key -> endpoint IP addresses."
  value       = { for key, endpoint in module.resolver_endpoints : key => endpoint.ip_addresses }
}

output "resolver_endpoint_rules" {
  description = "Map of resolver endpoint key -> resolver rules created by that endpoint module."
  value       = { for key, endpoint in module.resolver_endpoints : key => endpoint.rules }
}

output "resolver_firewall_rule_group_ids" {
  description = "Map of firewall rule group key -> rule group ID."
  value       = { for key, group in module.resolver_firewall_rule_groups : key => group.id }
}

output "resolver_firewall_rule_group_arns" {
  description = "Map of firewall rule group key -> rule group ARN."
  value       = { for key, group in module.resolver_firewall_rule_groups : key => group.arn }
}

output "resolver_firewall_rule_group_share_statuses" {
  description = "Map of firewall rule group key -> RAM share status."
  value       = { for key, group in module.resolver_firewall_rule_groups : key => group.share_status }
}

output "resolver_firewall_rule_group_domain_lists" {
  description = "Map of firewall rule group key -> domain lists created in that group."
  value       = { for key, group in module.resolver_firewall_rule_groups : key => group.domain_lists }
}

output "resolver_firewall_rule_group_rules" {
  description = "Map of firewall rule group key -> firewall rules created in that group."
  value       = { for key, group in module.resolver_firewall_rule_groups : key => group.rules }
}

output "resolver_firewall_rule_group_ram_resource_associations" {
  description = "Map of firewall rule group key -> RAM resource associations created for that group."
  value       = { for key, group in module.resolver_firewall_rule_groups : key => group.ram_resource_associations }
}
