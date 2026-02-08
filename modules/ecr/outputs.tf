# modules/ecr/outputs.tf

output "repository_url" {
  description = "The full URI of the ECR repository used for Docker push/pull"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}