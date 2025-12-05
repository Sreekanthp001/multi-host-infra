# 1. Security Groups

# Security Group for the Application Load Balancer (allows HTTP/S inbound)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-ALB-SG"
  description = "Allow all traffic to ALB"
  vpc_id      = var.vpc_id

  # HTTPS Ingress
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Ingress (for redirect)
  ingress {
    description = "HTTP from Internet (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for ECS Tasks (allows traffic only from the ALB)
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ECS-Tasks-SG"
  description = "Allow inbound traffic from ALB to ECS tasks"
  vpc_id      = var.vpc_id

  # Ingress from ALB on common application ports (e.g., 80)
  ingress {
    description     = "App traffic from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # All outbound traffic allowed (for dependencies, ECR pulls, logging)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "${var.project_name}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  enable_deletion_protection = false 

  tags = {
    Name = "${var.project_name}-ALB"
  }
}

# 3. AWS Certificate Manager (ACM) - Wildcard Certificate

# Combine the base domain and client domains for the certificate request
locals {
  domain_list = distinct(flatten([var.base_domain, "*.${var.base_domain}", var.client_domains, [for domain in var.client_domains : "*.${domain}"]]))
}

resource "aws_acm_certificate" "wildcard" {
  domain_name               = "*.${var.base_domain}"
  subject_alternative_names = local.domain_list
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-Wildcard-Cert"
  }
}

# 4. ALB Listeners

# HTTPS Listener (Port 443)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.wildcard.arn

  # Default action redirects traffic to a placeholder target group or returns fixed response
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Site not found: No routing rule matched. Use host header routing."
      status_code  = "404"
    }
  }
}

# HTTP Listener (Port 80) -> Redirects all traffic to HTTPS
resource "aws_lb_listener" "http_redirect" {
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

# 5. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-Cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-Cluster"
  }
}