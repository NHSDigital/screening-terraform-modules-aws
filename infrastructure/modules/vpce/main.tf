resource "aws_security_group" "vpce" {
  name        = "${var.name_prefix}-${var.vpce_name}-vpce"
  vpc_id      = var.vpc_id
  description = "${var.name_prefix}-${var.vpce_name} VPCE Security Group"

  tags = {
    # Used for naming resource in AWS console
    Name = "${var.name_prefix}-${var.vpce_name}-vpce"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "vpce_ingress_from_sg" {
  # only add this rule if a source security group id is specified
  count                    = var.source_sg_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = var.inbound_port
  to_port                  = var.outbound_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpce.id
  source_security_group_id = var.source_sg_id
  description              = "Allow ingress to VPCE on port ${var.inbound_port} from ${var.source_sg_id}"
}

resource "aws_security_group_rule" "vpce_ingress_from_cidr_range" {
  count             = var.ingress_cidr_range != "" ? 1 : 0
  type              = "ingress"
  from_port         = var.inbound_port
  to_port           = var.outbound_port
  protocol          = "tcp"
  security_group_id = aws_security_group.vpce.id
  cidr_blocks       = [var.ingress_cidr_range]
  description       = "Allow ingress to VPCE on port ${var.inbound_port} from ${var.ingress_cidr_range}"
}

resource "aws_security_group_rule" "vpce_egress" {
  type              = "egress"
  from_port         = var.outbound_port
  to_port           = var.outbound_port
  protocol          = "tcp"
  security_group_id = aws_security_group.vpce.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound traffic from VPCE on port ${var.outbound_port}"
}

resource "aws_vpc_endpoint" "endpoint" {
  vpc_id            = var.vpc_id
  service_name      = var.service_name
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.vpce.id
  ]
  private_dns_enabled = false

  subnet_ids = var.subnet_ids

  tags = {
    # Used for naming resource in AWS console
    Name = "${var.name_prefix}-${var.vpce_name}"
  }
}

resource "aws_route53_record" "vpc_endpoint" {
  count   = var.hosted_zone_name != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "${var.vpce_name}.${var.hosted_zone_name}"
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_vpc_endpoint.endpoint.dns_entry[0]["dns_name"]
    zone_id                = aws_vpc_endpoint.endpoint.dns_entry[0]["hosted_zone_id"]
  }
}

