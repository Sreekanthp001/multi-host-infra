# modules/ecr/variables.tf

variable "repository_name" {
  description = "The unique name for the ECR repository (e.g., frontend-app)"
  type        = string
}