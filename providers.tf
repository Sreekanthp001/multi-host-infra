# providers.tf (UPDATED)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default Provider (e.g., your infra region: us-west-2, or us-east-1 if preferred)
provider "aws" {
  region = var.aws_region # e.g., us-east-1
  # ... default tags ...
}

# Secondary Provider for ACM (MUST be us-east-1 for CloudFront compatibility)
provider "aws" {
  alias  = var.aws_region
  region = var.aws_region
}