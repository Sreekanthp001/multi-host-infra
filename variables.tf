# -----------------------------------------------------------------------------
# 1. GLOBAL PLATFORM VARIABLES
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region where the main infrastructure will be deployed (e.g., us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "A unique prefix for all resources created (e.g., 'vm-hosting')."
  type        = string
  default     = "vm-hosting" 
}

# -----------------------------------------------------------------------------
# 2. CLIENT CONFIGURATIONS (Unified Map for ALL Clients)
# -----------------------------------------------------------------------------

/*
   Defines all clients to be onboarded. 
   The key is the unique client ID (e.g., "sree84s-prod").
   The value is an object containing configuration details.
*/
variable "client_configs" {
  description = "A map of client configurations for dynamic and static hosting."
  type = map(object({
    domain_name           = string
    hosting_type          = string # Must be "dynamic" or "static"
    email_accounts        = list(string)
    docker_image_tag      = optional(string, "latest") # Required for "dynamic"
    s3_bucket_suffix      = optional(string, "")       # Custom suffix for static S3 bucket
    enable_email_forward  = optional(bool, false)      # Whether to set up SES forwarding
  }))
  
  default = {
    "sree84s-prod" = {
      domain_name          = "sree84s.site",
      hosting_type         = "dynamic",
      docker_image_tag     = "v1.2"
    },
    "calvio-store" = {
      domain_name          = "calvio.store",
      hosting_type         = "static"
    }
  }
}

variable "s3_bucket_prefix" {
  description = "A global prefix for all S3 bucket names to ensure global uniqueness."
  type        = string
  default     = "multi-host-assets"
}

variable "shared_r53_zone_id" {
  description = "The Route 53 Zone ID for the parent domain, if hosted zones are managed centrally (optional)."
  type        = string
  default     = ""
}

