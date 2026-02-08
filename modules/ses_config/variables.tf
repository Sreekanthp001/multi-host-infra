# modules/ses_config/variables.tf

variable "project_name" {
  description = "Project prefix for resource names"
  type        = string
}

variable "client_domains" {
  type        = map(any) # string nundi any ki marchu
  description = "Dynamic app domains"
}

variable "aws_region" {
  description = "AWS Region where SES is configured"
  type        = string
}

variable "forwarding_email" {
  description = "Personal email to receive forwarded SES messages"
  type        = string
}