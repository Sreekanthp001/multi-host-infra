output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "ecs_service_sg_id" {
  value = aws_security_group.ecs_tasks.id
}