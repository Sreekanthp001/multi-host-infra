# modules/ecs/outputs.tf
output "ecs_cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks_sg.id
}

output "ecs_task_exec_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "task_definition_arn" {
  description = "The ARN of the ECS Task Definition."
  value       = aws_ecs_task_definition.main.arn 
}