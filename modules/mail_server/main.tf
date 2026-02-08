resource "aws_security_group" "mail_server_sg" {
  name        = "${var.project_name}-mail-sg"
  description = "Allow mail traffic"
  vpc_id      = var.vpc_id

  # SMTP
  ingress {
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Submission
  ingress {
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SMTPS
  ingress {
    from_port   = 465
    to_port     = 465
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # IMAPS
  ingress {
    from_port   = 993
    to_port     = 993
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP/HTTPS (for Certbot)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mail_server" {
  ami           = var.ami_id
  instance_type = "t3.medium"
  subnet_id     = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.mail_server_sg.id]
  key_name      = var.key_name

  tags = {
    Name = "Business-Mail-Server-MX"
  }
}

resource "aws_eip" "mail_eip" {
  instance = aws_instance.mail_server.id
  domain   = "vpc"
}

# DNS for the Primary Mail Server
resource "aws_route53_record" "mx_record" {
  zone_id = var.main_zone_id
  name    = "mx.${var.main_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.mail_eip.public_ip]
}
