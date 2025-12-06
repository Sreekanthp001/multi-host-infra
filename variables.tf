# variables.tf (Root Directory)

variable "project_name" {
  type    = string
  default = "vm-hosting"
}

variable "aws_region" {
  description = "The AWS region where the main infrastructure will be deployed (e.g., us-east-1)."
  type        = string
  default     = "us-east-1" # Use your preferred region here
}

variable "client_domains" {
  description = "Map of client name to their domain name"
  type = map(string)
  default = {
    sree84s = "sree84s.site"
  }
}
# Add other global variables here as needed