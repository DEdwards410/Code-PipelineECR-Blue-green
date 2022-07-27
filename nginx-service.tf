resource "aws_ecs_service" "nginx" {
  name                               = "nginx-service-${var.environment}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.nginx.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = compact(concat(tolist([aws_security_group.nginx_tasks.id])))
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.blue.arn
    container_name   = "nginx"
    container_port   = 80
  }

  # depends_on = [
  # aws_lb_listener.main_blue_green,
  # ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}


# blue green

resource "aws_iam_role" "ecs-blue-green" {
  name = "ecs-bluegreen-code-deploy-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "amazon-code-deploy-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.ecs-blue-green.name
}
