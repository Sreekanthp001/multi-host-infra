variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "client_domains" {
  type        = map(any) # Changed to 'any' to support domain + priority objects
  description = "Dynamic app domains with priority"
}

variable "static_client_configs" {
  type        = map(any)
  description = "Static site domains"
}

variable "forwarding_email" {
  description = "The email address where SES will forward incoming emails"
  type        = string
}

variable "alert_email" {
  description = "The email address for CloudWatch alarm notifications"
  type        = string
}