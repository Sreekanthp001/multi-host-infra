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
    "sree84s-prod"  = "sree84s.site", 
    "calvio-store" = "calvio.store"   
    #"sree84s-dev"   = "dev.sree84s.site"  
  }
}
# Add other global variables here as needed

output "ses_smtp_username" {
  description = "The SES SMTP Username (Access Key ID)"
  value       = module.ses_configuration.smtp_username
  sensitive   = true
}

output "ses_smtp_password" {
  description = "The SES SMTP Password (Secret Access Key)"
  value       = module.ses_configuration.smtp_password
  sensitive   = true
}

variable "project_name" {
  description = "A unique prefix for all resources created (e.g., 'vm-hosting')."
  type        = string
  default     = "vm-hosting" # మీరు కావాలంటే దీన్ని మార్చవచ్చు
}