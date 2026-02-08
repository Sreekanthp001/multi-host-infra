# modules/client_deployment/outputs.tf

output "client_target_group_arns" {
  description = "Map of all client target group ARNs"
  value       = { for k, v in aws_lb_target_group.client_tg : k => v.arn }
}

output "client_service_names" {
  description = "Map of all deployed ECS service names"
  value       = { for k, v in aws_ecs_service.client_service : k => v.name }
}

output "listener_rule_ids" {
  description = "Map of all listener rule IDs"
  value       = { for k, v in aws_lb_listener_rule.host_rule : k => v.id }
}