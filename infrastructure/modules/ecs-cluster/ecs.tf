## ecs cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name       = "${var.name_prefix}-${var.name}"
  depends_on = [aws_iam_service_linked_role.ecs]
}

# ------------------------------------------------------------------------------
# Security Group for ECS app
# ------------------------------------------------------------------------------
resource "aws_security_group" "ecs_sg" {
  # vpc_id                 = data.aws_vpc.vpc.id
  vpc_id                 = var.vpc_id
  name                   = "${var.name_prefix}-${var.name}"
  description            = "Security group for ECS app"
  revoke_rules_on_delete = true
}

# ------------------------------------------------------------------------------
# ECS app Security Group Rules - OUTBOUND
# ------------------------------------------------------------------------------
resource "aws_security_group_rule" "ecs_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Allow outbound traffic from ECS"
  security_group_id = aws_security_group.ecs_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_service_linked_role" "ecs" {
  aws_service_name = "ecs.amazonaws.com"
}
