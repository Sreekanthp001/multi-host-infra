# modules/client_deployment/outputs.tf

output "client_target_group_arn" {
  description = "ARN of the created target group"
  value       = aws_lb_target_group.client_tg.arn
}

output "client_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.client_service.name
}

output "listener_rule_id" {
  description = "ID of the ALB listener rule"
  value       = aws_lb_listener_rule.host_rule.id
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the created target group"
  value       = aws_lb_target_group.client_tg.arn_suffix
}