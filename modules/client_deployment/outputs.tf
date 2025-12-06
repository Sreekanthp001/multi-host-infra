# modules/client_deployment/outputs.tf

output "target_group_arn" {
  description = "The ARN of the ECS Target Group created for this client."
  value       = aws_lb_target_group.client_tg["my_test_client"].arn
}

output "listener_rule_arn" {
  description = "The ARN of the ALB Listener Rule created for this client's domain."
  value       = aws_lb_listener_rule.host_rule.arn
}

output "ecs_service_name" {
  description = "The name of the ECS service deployed for this client."
  value       = aws_ecs_service.client_service["my_test_client"].name
}