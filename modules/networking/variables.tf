# modules/networking/variables.tf

variable "vpc_cidr" {
  description = "The CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string
}

variable "project_name" {
  description = "A unique name used as a prefix for all network resources"
  type        = string
}