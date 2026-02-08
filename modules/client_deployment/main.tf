# modules/client_deployment/main.tf

# 1. ECS Target Group (Per Client)
# Creates a unique target group for each client to handle internal routing.
resource "aws_lb_target_group" "client_tg" {
  for_each    = var.client_domains  
  name        = "${each.key}-tg"
  port        = 80 
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

  tags = {
    Name = "${each.key}-target-group"
  }
}

# 2. ALB Listener Rule (Per Client)
# Configures host-based routing to direct traffic based on the domain name.
resource "aws_lb_listener_rule" "host_rule" {
  for_each     = var.client_domains
  listener_arn = var.alb_https_listener_arn 
  
  # Dynamic priority assignment to support high volume of domains (100+)
  priority     = index(keys(var.client_domains), each.key) + 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.client_tg[each.key].arn
  }

  condition {
    host_header {
      values = [
        each.value,
        "*.${each.value}"
      ] 
    }
  }
}

# 3. ECS Service (Per Client)
# Deploys the application containers into the private subnets.
resource "aws_ecs_service" "client_service" {
  for_each        = var.client_domains
  name            = "${each.key}-svc"
  cluster         = var.ecs_cluster_id
  task_definition = var.task_definition_arn
  desired_count   = 2 
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.ecs_service_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.client_tg[each.key].arn
    container_name   = "client-container" 
    container_port   = 80 
  }

  lifecycle {
    ignore_changes = [desired_count] 
  }
}