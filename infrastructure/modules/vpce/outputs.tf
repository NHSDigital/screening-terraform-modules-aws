output "vpce_id" {
  description = "ID of the VPC interface endpoint for provider acceptance"
  value       = aws_vpc_endpoint.endpoint.id
}

output "vpce_state" {
  description = "Connection state of the VPC interface endpoint"
  value       = aws_vpc_endpoint.endpoint.state
}

output "vpce_arn" {
  description = "ARN of the VPC interface endpoint"
  value       = aws_vpc_endpoint.endpoint.arn
}

output "vpce_dns_name" {
  description = "DNS name of the VPC interface endpoint, or null until available with DNS entries"
  value       = aws_vpc_endpoint.endpoint.state == "available" ? try(aws_vpc_endpoint.endpoint.dns_entry[0]["dns_name"], null) : null
}

output "vpce_hosted_zone_id" {
  description = "Hosted zone ID for the VPC interface endpoint DNS, or null until available with DNS entries"
  value       = aws_vpc_endpoint.endpoint.state == "available" ? try(aws_vpc_endpoint.endpoint.dns_entry[0]["hosted_zone_id"], null) : null
}
