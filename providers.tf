terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a version compatible with your project
    }
  }

  # **** కొత్తగా చేర్చబడిన S3 Backend కాన్ఫిగరేషన్ ****
  backend "s3" {
    # ఇక్కడ మీరు మీ అసలు S3 బకెట్ పేరును ఉంచాలి!
    bucket  = "మీ-S3-బకెట్-పేరు" 
    key     = "multi-host-infra/terraform.tfstate"
    region  = "us-east-1" # Backend బకెట్ ఉన్న రీజియన్
    encrypt = true
  }
  # *******************************************************
}

# Default Provider (Uses the variable from variables.tf)
# providers.tf (In your ROOT directory)

# Primary provider (your project region)
provider "aws" {
  region = var.aws_region 
}

# Secondary provider for ACM certificates (MUST be us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}