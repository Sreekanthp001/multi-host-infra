# modules/client_deployment/outputs.tf

output "client_target_group_arns" {
  description = "ARNs of the created target groups"
  value       = { for k, v in aws_lb_target_group.client_tg : k => v.arn }
}

output "client_service_names" {
  description = "Names of the ECS services"
  value       = { for k, v in aws_ecs_service.client_service : k => v.name }
}

output "listener_rule_ids" {
  description = "IDs of the ALB listener rules"
  value       = { for k, v in aws_lb_listener_rule.host_rule : k => v.id }
}