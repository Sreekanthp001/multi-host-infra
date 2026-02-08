# dynamic_portfolio.tf
# Dynamic Hosting for Client Portfolio (sree84s.site)
# Parallel path to existing infrastructure

# Data source for existing ECS execution role
data "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-task-exec-role"
}

# 1. CloudWatch Log Group for Portfolio
resource "aws_cloudwatch_log_group" "portfolio_logs" {
  name              = "/ecs/${var.project_name}-portfolio"
  retention_in_days = 30
  
  tags = {
    Name = "${var.project_name}-portfolio-logs"
  }
}

# 2. Portfolio Task Definition
resource "aws_ecs_task_definition" "portfolio_task" {
  family                   = "${var.project_name}-portfolio-task"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "portfolio-container"
      image     = "${module.ecr.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.portfolio_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 3. Target Group for Portfolio
resource "aws_lb_target_group" "portfolio_tg" {
  name        = "${var.project_name}-portfolio-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "${var.project_name}-portfolio-tg"
  }
}

# 4. ALB Listener Rule for Portfolio (High Priority)
resource "aws_lb_listener_rule" "portfolio_rule" {
  listener_arn = module.alb.https_listener_arn
  priority     = 50 # Higher priority than generic client rules (100+)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.portfolio_tg.arn
  }

  condition {
    host_header {
      values = ["sree84s.site", "www.sree84s.site"]
    }
  }
}

# 5. ECS Service for Portfolio
resource "aws_ecs_service" "portfolio_service" {
  name            = "${var.project_name}-portfolio-svc"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.portfolio_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.networking.private_subnets
    security_groups  = [module.ecs.ecs_service_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.portfolio_tg.arn
    container_name   = "portfolio-container"
    container_port   = 80
  }
  
  # Ensure the listener rule is created before service
  depends_on = [aws_lb_listener_rule.portfolio_rule]
}
