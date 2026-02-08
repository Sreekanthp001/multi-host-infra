output "cluster_id" {
  # Resource name 'main' match avvali
  value = aws_ecs_cluster.main.id
}

output "task_definition_arn" {
  # Resource name 'main' match avvali (ne daggara 'app' ledu)
  value = aws_ecs_task_definition.main.arn
}

output "ecs_service_sg_id" {
  # Resource name 'ecs_tasks_sg' match avvali
  value = aws_security_group.ecs_tasks_sg.id
}