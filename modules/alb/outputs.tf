output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}