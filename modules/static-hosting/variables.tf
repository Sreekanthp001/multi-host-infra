// modules/static-hosting/variables.tf

variable "client_id" {
  description = "The unique identifier for the client (e.g., calvio-store)."
  type        = string
}

variable "client_domain" {
  description = "The domain name for the static client."
  type        = string
}

variable "s3_prefix" {
  description = "Global prefix for the S3 bucket name."
  type        = string
}

variable "s3_suffix" {
  description = "Client-specific suffix for the S3 bucket name (e.g., calvio-assets)."
  type        = string
  default     = "" // Set default to empty string if not provided in client_configs
}