output "vpce_arn" {
  description = "ARN of the VPC interface endpoint"
  value       = aws_vpc_endpoint.endpoint.arn
}

output "vpce_dns_name" {
  description = "DNS name of the VPC interface endpoint"
  value       = aws_vpc_endpoint.endpoint.dns_entry[0]["dns_name"]
}

output "vpce_hosted_zone_id" {
  description = "Hosted zone ID for the VPC interface endpoint DNS"
  value       = aws_vpc_endpoint.endpoint.dns_entry[0]["hosted_zone_id"]
}
