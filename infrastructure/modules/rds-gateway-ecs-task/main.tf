data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = trimsuffix(substr("${var.name_prefix}-rds-access-gateway-ecs-task", 0, 64), "-")
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role" "ecs_execution_role" {
  # limit to 64 characters and trim any trailing hyphen
  name               = trimsuffix(substr("${var.name_prefix}-rds-access-gateway-ecs-execution", 0, 64), "-")
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ecs_execution_role_policy" {
  name        = "${var.name_prefix}-rds-access-gateway-ecs-execution"
  description = "Policy for ${var.name_prefix} ECS execution"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:eu-west-2:${var.aws_account_id}:log-group:/ecs/${var.name_prefix}-rds-access-gateway-ecs-task*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_role_policy.arn
}


resource "aws_ecs_service" "ecs_service" {
  name                   = "${var.name_prefix}-rds-access-gateway"
  cluster                = var.ecs_cluster_name
  task_definition        = aws_ecs_task_definition.task_definition.arn
  launch_type            = "FARGATE"
  scheduling_strategy    = "REPLICA"
  desired_count          = var.replica_task_count
  enable_execute_command = true

  network_configuration {
    subnets          = var.private_subnet_ids
    assign_public_ip = false
    security_groups = [
      aws_security_group.ecs_task_sg.id
    ]
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.name_prefix}-rds-access-gateway"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode(
    [
      {
        "name" : "${var.name_prefix}-rds-access-gateway",
        "image" : var.image_name,
        "essential" : true,
        "command" : ["sleep", "infinity"],
        "readonlyRootFilesystem" : true,
        "environment" : [],
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-group" : aws_cloudwatch_log_group.log_group.name,
            "awslogs-region" : "eu-west-2",
            "awslogs-stream-prefix" : "ecs"
          }
        },
        "networkMode" : "awsvpc",
        "linuxParameters" : {
          # temporary filesystem for SSM agent so these directories are writable
          # size is in MiB and uses task memory
          "tmpfs" : [
            {
              "containerPath" : "/var/log/amazon",
              "size" : 200,
              "mountOptions" : ["noexec", "nosuid", "nodev"]
            },
            {
              "containerPath" : "/var/lib/amazon",
              "size" : 200,
              "mountOptions" : ["noexec", "nosuid", "nodev"]
            }
          ]
        }
      }
    ]
  )
  depends_on = [aws_cloudwatch_log_group.log_group]
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${var.name_prefix}-rds-access-gateway-ecs-task"
  retention_in_days = 14
}

resource "aws_security_group" "ecs_task_sg" {
  name        = "${var.name_prefix}-rds-access-gateway-ecs-task"
  description = "Allow rds-access-gateway connections"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_all_outbound" {
  description       = "Allow outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_task_sg.id
}

# Allow traffic in to the RDS SG from the ec2 instance
resource "aws_security_group_rule" "rds_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.rds_sg_id
  source_security_group_id = aws_security_group.ecs_task_sg.id
  description              = "Allow access in from the rds-access-gateway ecs task instance"
}
