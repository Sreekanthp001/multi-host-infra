output "repository_url" {
  description = "The full URI of the ECR repository."
  value       = aws_ecr_repository.main.repository_url
}