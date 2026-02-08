# modules/ecs/outputs.tf

output "ecs_cluster_id" {
  description = "The ID of the created ECS Cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_tasks_sg_id" {
  description = "Security Group ID for the ECS tasks"
  value       = aws_security_group.ecs_tasks_sg.id
}

output "task_definition_arn" {
  description = "The ARN of the ECS Task Definition"
  value       = aws_ecs_task_definition.main.arn 
}