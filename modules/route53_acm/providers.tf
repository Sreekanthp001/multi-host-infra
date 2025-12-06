# modules/route53_acm/providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a version compatible with your project
    }
  }
}