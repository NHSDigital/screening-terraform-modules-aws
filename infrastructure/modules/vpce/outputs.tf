output "vpce_arn" {
  value = aws_vpc_endpoint.endpoint.arn
}

output "vpce_dns_name" {
  value = aws_vpc_endpoint.endpoint.dns_entry[0]["dns_name"]
}

output "vpce_hosted_zone_id" {
  value = aws_vpc_endpoint.endpoint.dns_entry[0]["hosted_zone_id"]
}
