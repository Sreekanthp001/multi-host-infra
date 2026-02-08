# modules/ecs/main.tf

# 1. ECS Cluster with Monitoring enabled
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" 
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = "Production"
  }
}

# 2. IAM Role for ECS Task Execution
# Allows ECS to pull images from ECR and send logs to CloudWatch.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Standard policy for ECR and CloudWatch access
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 3. Security Group for ECS Tasks
# Restricts traffic so that only the ALB can communicate with the containers.
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.project_name}-ecs-task-sg"
  description = "Allows inbound traffic only from the ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ecs-tasks-sg" }
}

# 4. CloudWatch Log Group for Container Logs
resource "aws_cloudwatch_log_group" "client_log_group" {
  name              = "/ecs/${var.project_name}-client-app"
  retention_in_days = 30 
  
  tags = { Name = "ClientAppLogGroup" }
}

# 5. ECS Task Definition
# Defines how the container should run (CPU, Memory, Image).
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-task"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "client-container"
      image     = "${var.ecr_repository_url}:latest" # Dynamic URL avoids hardcoding account IDs
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
          "awslogs-group"         = aws_cloudwatch_log_group.client_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}