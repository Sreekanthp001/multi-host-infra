# variables.tf
variable "aws_region" {
  description = "AWS Region to deploy to"
  default     = "us-east-1" # Change if you prefer another region
}

variable "project_name" {
  description = "Base name for resources"
  default     = "vm-hosting"
}

# We will add domain variables later