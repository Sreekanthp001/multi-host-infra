# modules/alb/outputs.tf

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB to be used in Route53 Aliases"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB for Route53"
  value       = aws_lb.main.zone_id
}

output "alb_https_listener_arn" {
  description = "The ARN of the HTTPS listener for host-based routing rules"
  value       = aws_lb_listener.https.arn
}

output "alb_sg_id" {
  description = "The Security Group ID of the ALB"
  value       = aws_security_group.alb_sg.id
}