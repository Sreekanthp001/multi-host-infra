resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.repository_name
  }
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = jsonencode({
    rules = [
      {
        "rulePriority" : 1,
        "action" = {
          "type" = "expire"
        },
        "selection" = {
          "tagStatus"   = "untagged"
          "countType"   = "sinceImagePushed"
          "countUnit"   = "days"
          "countNumber" = 7
        }
      }
    ]
  })
}