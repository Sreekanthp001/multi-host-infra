# modules/client_deployment/main.tf

# 1. ECS Target Group (Per Client)
resource "aws_lb_target_group" "client_tg" {
  for_each = var.client_domains  
  name        = "${each.key}-tg"
  port        = 8080 # Application port inside the container
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 2. ALB Listener Rule (Per Client)
# This routes traffic from the shared ALB's HTTPS listener to this client's Target Group.
resource "aws_lb_listener_rule" "host_rule" {
  for_each = var.client_domains
  listener_arn = var.alb_https_listener_arn 
  priority     = index(keys(var.client_domains), each.key) + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.client_tg[each.key].arn
  }

  # Condition 1: Match traffic for the root domain (e.g., venturemond.com)
  condition {
    host_header {
      values = [each.value] 
    }
  }
  
  # Condition 2: Match traffic for wildcard subdomains (e.g., *.venturemond.com)
  condition {
    host_header {
      values = ["*.${each.value}"] 
    }
  }
}

# 3. ECS Service (Per Client)
resource "aws_ecs_service" "client_service" {
  for_each = var.client_domains

  name            = "${each.key}-svc"
  cluster         = var.ecs_cluster_id
  task_definition = var.task_definition_arn
  desired_count   = 2 
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets         = var.private_subnets
    security_groups = [var.ecs_service_security_group_id]
    assign_public_ip = false
  }

  # Connects the ECS service to the specific Target Group
  load_balancer {
    target_group_arn = aws_lb_target_group.client_tg[each.key].arn
    container_name   = "client-container" # Must match the name in your task definition
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count] # Allows autoscaling to adjust desired_count
  }
}