# variables.tf (Root Directory)

variable "project_name" {
  type    = string
  default = "vm-hosting"
}

variable "aws_region" {
  description = "The AWS region where the main infrastructure will be deployed (e.g., us-west-2)."
  type        = string
  default     = "us-west-2" # Use your preferred region here
}

variable "client_domains" {
  description = "Map of client name to their domain name"
  type = map(string)
  default = {
    venturemond = "venturemond.com"
    sampleclient = "sampleclient.com"
  }
}
# Add other global variables here as needed