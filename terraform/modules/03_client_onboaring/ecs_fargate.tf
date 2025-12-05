# Resources only provisioned if site_type is 'fargate'
locals {
  is_fargate = var.site_type == "fargate"
}

# 1. ECR Repository for the Docker Image
resource "aws_ecr_repository" "client_repo" {
  count = local.is_fargate ? 1 : 0
  name  = "${var.project_name}/client-${var.domain_name}"
  
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# 2. IAM Roles for ECS Tasks and Execution
resource "aws_iam_role" "ecs_execution" {
  count = local.is_fargate ? 1 : 0
  name  = "${var.project_name}-${var.domain_name}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  count      = local.is_fargate ? 1 : 0
  role       = aws_iam_role.ecs_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 3. ECS Task Definition
resource "aws_ecs_task_definition" "client" {
  count                    = local.is_fargate ? 1 : 0
  family                   = "${var.project_name}-${var.domain_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" 
  memory                   = "512" 
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  container_definitions = jsonencode([
    {
      name      = var.domain_name,
      image     = aws_ecr_repository.client_repo[0].repository_url, # ECR URL will be overwritten by CI/CD
      cpu       = 256,
      memory    = 512,
      essential = true,
      portMappings = [
        {
          containerPort = 80, 
          hostPort      = 80
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.domain_name}",
          "awslogs-region"        = "us-east-1",
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 4. CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "client_log" {
  count = local.is_fargate ? 1 : 0
  name  = "/ecs/${var.project_name}-${var.domain_name}"
  retention_in_days = 30
}

# 5. ECS Service
resource "aws_ecs_service" "client" {
  count            = local.is_fargate ? 1 : 0
  name             = "${var.project_name}-${var.domain_name}-service"
  cluster          = var.ecs_cluster_id
  task_definition  = aws_ecs_task_definition.client[0].arn
  launch_type      = "FARGATE"
  desired_count    = 2 

  # Networking for Fargate
  network_configuration {
    subnets          = var.private_subnet_ids 
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  # Load Balancer Integration
  load_balancer {
    target_group_arn = aws_lb_target_group.client[0].arn
    container_name   = var.domain_name
    container_port   = 80
  }
}

# 6. ALB Target Group for the ECS Service
resource "aws_lb_target_group" "client" {
  count = local.is_fargate ? 1 : 0
  name        = "${var.project_name}-${var.domain_name}-TG"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id 
  target_type = "ip"
  
  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
}

# 7. ALB Listener Rule (Host Header Routing)
resource "aws_lb_listener_rule" "client_host_rule" {
  count        = local.is_fargate ? 1 : 0
  listener_arn = var.alb_listener_arn 
  priority     = 10 

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.client[0].arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }
}

# Output the ECR Repository URL for CI/CD
output "ecr_repository_url" {
  description = "ECR repository URL for the dynamic client."
  value       = local.is_fargate ? aws_ecr_repository.client_repo[0].repository_url : "N/A"
}