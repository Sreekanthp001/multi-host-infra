# modules/static_hosting/variables.tf

variable "project_name" {
  description = "Prefix for all static hosting resources"
  type        = string
}

variable "static_client_configs" {
  description = "Map of static site configurations. Key is client-id, value contains domain_name."
  type        = map(any)
}

variable "acm_certificate_arn" {
  description = "The ARN of the SSL certificate for custom domain HTTPS"
  type        = string
}