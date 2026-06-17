
# VPC Endpoint Service
resource "aws_vpc_endpoint_service" "service" {
  acceptance_required        = true
  network_load_balancer_arns = [aws_lb.nlb.arn]
  tags = {
    Name = var.vpces_name
  }
}

# NLB that forwards to ALB IPs
resource "aws_lb" "nlb" {
  name               = var.nlb_name
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.nlb_sg.id]

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = true
  }
}
resource "aws_security_group" "nlb_sg" {
  name        = var.nlb_name
  description = "Security group for NLB"
  vpc_id      = var.vpc_id
}


resource "aws_lb_target_group" "nlb_tg" {
  name        = var.tg_name
  port        = 443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb"

  health_check {
    protocol            = "HTTPS"
    path                = "/bss/info"
    matcher             = "200-404" # if ALB returns 404 its enough for now to confirm its healthy
    port                = "traffic-port"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_target_group_attachment" "alb_ip_targets" {

  target_group_arn = aws_lb_target_group.nlb_tg.arn
  target_id        = var.alb_arn
  port             = 443
}


# NLB Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}

#Allow other accounts to use this VPCE service
data "aws_secretsmanager_secret" "pi_account_id" {
  name = var.allowed_principal_secret_name
}

data "aws_secretsmanager_secret_version" "pi_account_id_version" {
  secret_id = data.aws_secretsmanager_secret.pi_account_id.id
}

locals {
  pi_account_id = jsondecode(data.aws_secretsmanager_secret_version.pi_account_id_version.secret_string)["aws_account_id"]
}

resource "aws_vpc_endpoint_service_allowed_principal" "allowed_principal" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.service.id
  principal_arn           = "arn:aws:iam::${local.pi_account_id}:root"
}


resource "aws_security_group_rule" "allow_https_from_nlb" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.target_alb_sg_id
  source_security_group_id = aws_security_group.nlb_sg.id
  description              = "Allow HTTPS traffic from IUVO from IUVO NLB TF"
}



data "aws_ssm_parameter" "allowed_vmc_ips" {
  name = var.ssm_parameter_name
}
locals {
  vmc_ips = [for ip in split(",", data.aws_ssm_parameter.allowed_vmc_ips.value) : trimspace(ip)]
}

resource "aws_security_group_rule" "allowed_https" {
  for_each = { for ip in nonsensitive(local.vmc_ips) : ip => ip }

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.nlb_sg.id
  description       = "ingress from IUVO VMC ${each.value}"
}

resource "aws_security_group_rule" "allowed_egress_to_alb" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.target_alb_sg_id
  security_group_id        = aws_security_group.nlb_sg.id
  description              = "egress to app load balancer"
}
