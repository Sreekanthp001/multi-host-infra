# providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 Backend configuration - ఇది తప్పనిసరిగా terraform { ... } లోపల ఉండాలి.
  backend "s3" {
    bucket  = "sree84s-tf-remote-state-001" # మీ కొత్త S3 బకెట్ పేరు
    key     = "multi-host-infra/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# ------------------------------------------------------------------
# Provider blocks తప్పనిసరిగా terraform { ... } బ్లాక్ వెలుపల ఉండాలి.

# Primary provider (your project region)
provider "aws" {
  region = var.aws_region 
}

# Secondary provider for ACM certificates (MUST be us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}