variable "project_name" {
  description = "The prefix to use for all SES related resources."
  type        = string
}

variable "client_domains" {
  description = "A map of client keys (e.g., 'sree84s') to their full domain names (e.g., 'sree84s.site')."
  type        = map(string)
}

variable "aws_region" {
  description = "The AWS region where SES is configured (e.g., us-east-1)."
  type        = string
}

variable "forwarding_email" {
  description = "Email address to forward incoming SES mail to (e.g., your personal Gmail ID)."
  type        = string
}