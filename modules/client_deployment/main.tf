# modules/client_deployment/main.tf

# 1. ECS Target Group (Single Client per module instance)
resource "aws_lb_target_group" "client_tg" {
  # Nuvvu for_each teesi var.client_name use cheyali
  name        = "${var.project_name}-${var.client_name}-tg"
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
    Name = "${var.client_name}-target-group"
  }
}

# 2. ALB Listener Rule (Single Client per module instance)
resource "aws_lb_listener_rule" "host_rule" {
  listener_arn = var.alb_https_listener_arn 
  
  # Priority logic: Multiple clients unnapudu unique ga undali
  # Root nundi priority pass cheyadam best, or use dynamic logic
  priority     = var.priority_index + 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.client_tg.arn
  }

  condition {
    host_header {
      values = [
        # var.client_domains map lo unna values ni access chestunnam
        values(var.client_domains)[0],
        "*.${values(var.client_domains)[0]}"
      ] 
    }
  }
}

# 3. ECS Service (Single Client per module instance)
resource "aws_ecs_service" "client_service" {
  name            = "${var.project_name}-${var.client_name}-svc"
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
    target_group_arn = aws_lb_target_group.client_tg.arn
    container_name   = "client-container" 
    container_port   = 80 
  }

  lifecycle {
    ignore_changes = [desired_count] 
  }
}