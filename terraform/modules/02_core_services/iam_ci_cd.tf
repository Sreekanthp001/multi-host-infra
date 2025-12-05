resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # Standard GitHub Thumbprint (valid as of 2024)
  thumbprint_list = ["6930fd8b44bbba305a41be17f69436d3a8e9e1c3"] 
}

# 2. IAM Policy for CI/CD Deployments
# This policy grants the necessary permissions to deploy both static and dynamic sites.
resource "aws_iam_policy" "ci_cd_deployment" {
  name        = "${var.project_name}-CICD-DeploymentPolicy"
  description = "Permissions for GitHub Actions to deploy static and Fargate sites."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ECR Permissions (for Fargate deployment)
      {
        Sid    = "EcrAccess",
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = "*"
      },
      # ECS Deployment Permissions (to update the service with new image)
      {
        Sid    = "EcsUpdateService",
        Effect = "Allow",
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DescribeClusters",
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition"
        ],
        Resource = "*"
      },
      # S3 Permissions (for static site content sync)
      {
        Sid    = "S3Sync",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        # IMPORTANT: Update these resources with your placeholder bucket names
        Resource = [
          "arn:aws:s3:::venturemond.com",      
          "arn:aws:s3:::venturemond.com/*"
        ]
      },
      # CloudFront Invalidation (to clear cache after static deploy)
      {
        Sid    = "CloudFrontInvalidation",
        Effect = "Allow",
        Action = ["cloudfront:CreateInvalidation", "cloudfront:GetDistribution"]
        Resource = "*" 
      },
      # CloudWatch Logs 
      {
        Sid = "CloudWatchLogs",
        Effect = "Allow",
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:us-east-1:*:log-group:/ecs/*"
      }
    ]
  })
}

# 3. IAM Role that GitHub Actions will Assume
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-GitHubActions-Role"
  
  # Trust relationship policy allows GitHub to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
            # IMPORTANT: REPLACE ME with your GitHub org/repo name (e.g., "repo:my-org/my-repo:*" )
            "token.actions.githubusercontent.com:sub" : "repo:YOUR_GITHUB_ORGANIZATION/YOUR_REPOSITORY_NAME:*" 
          }
        }
      }
    ]
  })
}

# 4. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "ci_cd_deployment" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ci_cd_deployment.arn
}