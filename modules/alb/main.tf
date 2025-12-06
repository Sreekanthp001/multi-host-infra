# modules/alb/main.tf

# 1. Security Group for the ALB (Allows all incoming HTTPS traffic)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTPS and HTTP traffic to ALB"
  vpc_id      = var.vpc_id

  # HTTPS Ingress
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Ingress (for redirect/testing, though we enforce HTTPS)
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress (outbound: standard security best practice)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# 2. Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids # ALB lives in public subnets
  enable_deletion_protection = false # Set to true in a real production environment
  
  tags = { Name = "${var.project_name}-alb" }
}

# 3. HTTPS Listener (Required for production, using ACM certificate)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.acm_certificate_arn # We pass this in from Route53 module
  
  # Default action - essential for ALB setup; routes to a simple 404/default page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found - No Host Header Match"
      status_code  = "404"
    }
  }
}

# 4. HTTP Listener (To redirect HTTP traffic to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Action: Redirect to HTTPS on port 443
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}