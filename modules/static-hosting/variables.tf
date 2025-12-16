// modules/static-hosting/variables.tf (Slightly Cleaned Up)

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
