variable "aws_region" {
  description = "The AWS region to deploy to."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name to be used as a prefix for all resources."
  type        = string
  default     = "ClientHostingInfra"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use (e.g., us-east-1a, us-east-1b)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}