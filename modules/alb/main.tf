# modules/alb/main.tf

# Security Group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Controls inbound traffic to the Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTPS Ingress: Standard for production-grade hosting
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Ingress: Required for the 301 redirect to HTTPS
  ingress {
    description = "Allow HTTP for redirection"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic: Allow all to internal services
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = "Production"
  }
}

# The Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
  
  enable_deletion_protection = false # Set to true for production environments

  tags = {
    Name        = "${var.project_name}-alb"
    ManagedBy   = "Terraform"
  }
}

# HTTPS Listener: Entry point for all secure client domains
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn
  
  # Default action: Provides a fallback if no host-header matches
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Error 404: No host-header matched in the request."
      status_code  = "404"
    }
  }
  
  # Hard dependency to ensure certificates are valid before the listener is active
  depends_on = [
    var.acm_validation_resource 
  ]
}

# HTTP Listener: Automatic redirection to secure HTTPS endpoint
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}