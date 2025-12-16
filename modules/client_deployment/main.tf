# modules/client_deployment/main.tf

# 1. ECS Target Group (Per Client)
resource "aws_lb_target_group" "client_tg" {
  #for_each = var.client_domains  
  name        = "${var.client_id}-tg"
  port        = 80 # Application port inside the container
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
// modules/client_deployment/main.tf

resource "aws_lb_listener_rule" "host_rule" {
  // for_each is intentionally removed/commented out.

  listener_arn = var.alb_https_listener_arn
  
  // 1. FIX: Remove the old priority logic. 
  // We need a new input variable 'priority' from the root module.
  priority     = var.listener_priority // Assuming a new input variable is created.

  action {
    type             = "forward"
    // 2. FIX: Remove [each.key]. client_tg is a single resource in this module.
    target_group_arn = aws_lb_target_group.client_tg.arn
  }

  condition {
    host_header {
      // 3. FIX: Replace each.value with var.domain_name input variable
      values = [
        var.domain_name,
        "www.${var.domain_name}" // Add www subdomain rule
      ]
    }
  }
}

# 3. ECS Service (Per Client)
resource "aws_ecs_service" "client_service" {
  // for_each is intentionally commented out/removed. 
  // The root module's for_each handles the loop.

  // 1. FIX: Replace each.key with the input variable var.client_id
  name            = "${var.client_id}-svc"
  
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
    // 2. FIX: Remove [each.key] as client_tg should be a single resource in this module.
    target_group_arn = aws_lb_target_group.client_tg.arn
    
    container_name   = "client-container" // Must match the name in your task definition
    container_port   = 80 
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}