# providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Ideally, use an S3 backend for state, but for now we use local for simplicity
  # backend "s3" { ... } 
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Venturemond-Hosting"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}