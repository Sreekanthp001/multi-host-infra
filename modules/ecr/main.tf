# modules/ecr/main.tf

# 1. Amazon ECR Repository
# Stores Docker images for the client applications.
resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Allows deletion even if images exist

  image_scanning_configuration {
    scan_on_push = true # Automatically scans for vulnerabilities on every push
  }

  tags = {
    Name        = var.repository_name
    Project     = "Venturemond"
    ManagedBy   = "Terraform"
  }
}

# 2. ECR Lifecycle Policy
# Automatically cleans up old or untagged images to save on storage costs.
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"
        action = {
          type = "expire"
        }
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 10 tagged images"
        action = {
          type = "expire"
        }
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
      }
    ]
  })
}