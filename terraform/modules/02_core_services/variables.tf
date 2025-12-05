variable "project_name" {
  description = "Project name prefix."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of Public Subnet IDs for ALB deployment."
  type        = list(string)
}

variable "base_domain" {
  description = "The primary domain name used to host the ACM certificate."
  type        = string
}

variable "client_domains" {
  description = "List of additional client domain names to include in the ACM certificate."
  type        = list(string)
  default     = []
}