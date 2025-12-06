# modules/ecs/main.tf

# 1. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" # Good for monitoring
  }

  tags = { Name = "${var.project_name}-cluster" }
}

# 2. IAM Role for ECS Tasks (Permissions the container app needs)
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

# 3. Policy Attachments for logging and pulling ECR images
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 4. Security Group for ECS Tasks (Allows inbound traffic only from the ALB)
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.project_name}-ecs-task-sg"
  description = "Allow inbound traffic from ALB only"
  vpc_id      = var.vpc_id

  # Ingress: Allow traffic on port 8080 (our container port) only from the ALB's security group
  ingress {
    description     = "From ALB"
    from_port       = 8080 # Standard Nginx container port
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  # Egress: Allows outbound connection (e.g., to SES, NAT Gateway)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ecs-tasks-sg" }
}