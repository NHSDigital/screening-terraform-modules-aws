## ecs cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.name_prefix}-${var.name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  depends_on = [data.aws_iam_role.ecs]
}

# ------------------------------------------------------------------------------
# Security Group for ECS app
# ------------------------------------------------------------------------------
resource "aws_security_group" "ecs_sg" {
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
  count            = var.create_ecs_service_role ? 1 : 0
  aws_service_name = "ecs.amazonaws.com"
}

# to allow referencing the existing service linked role if not created
data "aws_iam_role" "ecs" {
  name       = "AWSServiceRoleForECS"
  depends_on = [aws_iam_service_linked_role.ecs]
}
# sns topic for cloudwatch alarms
data "aws_sns_topic" "alert" {
  name = var.name_prefix
}

# ##############################################################
# # CloudWatch Alarm for ECS Cluster
# ##############################################################

resource "aws_cloudwatch_metric_alarm" "task_cpu_utilization_alarm" {
  # Intent            : "This alarm is used to detect high CPU utilization for tasks in the ECS cluster. Consistent high CPU utilization can indicate that the tasks are under stress and might need more CPU resources or optimization to maintain performance."
  # Threshold Justification : "Set the threshold to about 80% of the task's CPU reservation. You can adjust this value based on your acceptable CPU utilization for the tasks. For some workloads, consistently high CPU utilization might be normal, while for others, it might indicate performance issues or the need for more resources."

  alarm_name                = "${var.name_prefix}-${var.name}-task-cpu-utilization-alarm"
  alarm_description         = "This alarm helps you detect high CPU utilization of tasks in your ECS cluster. If task CPU utilization is consistently high, you might need to optimize your tasks or increase their CPU reservation."
  actions_enabled           = true
  alarm_actions             = [data.aws_sns_topic.alert.arn]
  ok_actions                = [data.aws_sns_topic.alert.arn]
  insufficient_data_actions = []
  metric_name               = "TaskCpuUtilization"
  namespace                 = "ECS/ContainerInsights"
  statistic                 = "Average"
  period                    = 60
  dimensions = {
    ClusterName = "${var.name_prefix}-${var.name}"
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "task_memory_utilization_alarm" {
  # Intent            : "This alarm is used to detect high memory utilization for tasks in the ECS cluster. Consistent high memory utilization can indicate that the task is under memory pressure and might need more memory resources or optimization to maintain stability."
  # Threshold Justification : "Set the threshold to about 80% of the task's memory reservation. You can adjust this value based on your acceptable memory utilization for the tasks. For some workloads, consistently high memory utilization might be normal, while for others, it might indicate memory pressure or the need for more resources."

  alarm_name                = "${var.name_prefix}-${var.name}-task-memory-utilization-alarm"
  alarm_description         = "This alarm helps you detect high memory utilization of tasks in your ECS cluster. If memory utilization is consistently high, you might need to optimize your tasks or increase the memory reservation."
  actions_enabled           = true
  alarm_actions             = [data.aws_sns_topic.alert.arn]
  ok_actions                = [data.aws_sns_topic.alert.arn]
  insufficient_data_actions = []
  metric_name               = "TaskMemoryUtilization"
  namespace                 = "ECS/ContainerInsights"
  statistic                 = "Average"
  period                    = 60
  dimensions = {
    ClusterName = "${var.name_prefix}-${var.name}"
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}



