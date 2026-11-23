mock_provider "aws" {
  alias = "offline"
}

variables {
  name_prefix        = "bcss-test"
  vpce_name          = "oracle-db-privatelink"
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-0123456789abcdef0"]
  service_name       = "com.amazonaws.vpce.eu-west-2.vpce-svc-0123456789abcdef0"
  inbound_port       = 1529
  outbound_port      = 1529
  ingress_cidr_range = "10.0.0.0/16"
  hosted_zone_name   = ""
  hosted_zone_id     = ""
}

run "pending_acceptance" {
  command   = apply
  state_key = "pending_acceptance"

  providers = {
    aws = aws.offline
  }

  override_resource {
    target = aws_vpc_endpoint.endpoint
    values = {
      id        = "vpce-0123456789abcdef0"
      state     = "pendingAcceptance"
      dns_entry = []
    }
  }

  assert {
    condition     = output.vpce_dns_name == null && output.vpce_hosted_zone_id == null
    error_message = "Pending acceptance must not consume DNS entries."
  }

  assert {
    condition     = output.vpce_id == "vpce-0123456789abcdef0" && output.vpce_state == "pendingAcceptance"
    error_message = "The endpoint ID and state must be available for provider acceptance."
  }
}

run "available_without_dns" {
  command   = apply
  state_key = "available_without_dns"

  providers = {
    aws = aws.offline
  }

  override_resource {
    target = aws_vpc_endpoint.endpoint
    values = {
      state     = "available"
      dns_entry = []
    }
  }

  assert {
    condition     = output.vpce_dns_name == null && output.vpce_hosted_zone_id == null
    error_message = "An empty DNS list must remain safe even when the endpoint is available."
  }
}

run "available_with_dns" {
  command   = apply
  state_key = "available_with_dns"

  providers = {
    aws = aws.offline
  }

  override_resource {
    target = aws_vpc_endpoint.endpoint
    values = {
      state     = "available"
      dns_entry = [{ dns_name = "oracle.example.com", hosted_zone_id = "Z0123456789EXAMPLE" }]
    }
  }

  assert {
    condition     = output.vpce_dns_name == "oracle.example.com" && output.vpce_hosted_zone_id == "Z0123456789EXAMPLE"
    error_message = "An accepted endpoint must expose its regional DNS entry."
  }
}
