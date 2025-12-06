# modules/alb/outputs.tf
output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_listener_arn_https" {
  value = aws_lb_listener.https.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}