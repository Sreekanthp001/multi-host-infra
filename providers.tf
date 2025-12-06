# providers.tf 

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default Provider (Used for VPC, ALB, ECS, Route53 Zones)
# Let's assume you're deploying your main infrastructure in us-west-2 (Oregon) 
# or keep it as us-east-1 if you prefer everything there.
variable "aws_region" {
  default = "us-west-2" # Example region where infrastructure will live
}
provider "aws" {
  region = var.aws_region 
  # ... default tags ...
}

# Secondary Provider for ACM (MUST be us-east-1 for CloudFront compatibility)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}