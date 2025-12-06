# providers.tf (Root Directory - CORRECTED)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default Provider (Uses the variable from variables.tf)
provider "aws" {
  region = var.aws_region
}

# Secondary Provider for ACM/CloudFront (MUST be us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}