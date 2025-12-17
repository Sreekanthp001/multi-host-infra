variable "client_id" {
  description = "The unique identifier for the client (e.g., calvio-store)."
  type        = string
}

variable "domain_name" { 
  description = "The root domain name for the static client site (e.g., calvio.store)."
  type        = string
}

variable "s3_prefix" {
  description = "Global prefix for the S3 bucket name."
  type        = string
}

variable "s3_suffix" {
  description = "Client-specific suffix for the S3 bucket name (e.g., calvio-assets)."
  type        = string
  default     = ""
}

# New variables to avoid duplicate resources
variable "hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID created in the route53_acm module"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ACM Certificate ARN created in the route53_acm module"
  type        = string
}