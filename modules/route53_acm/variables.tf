# modules/route53_acm/variables.tf

variable "domain_names" {
  description = "List of all domain names to include in the SSL certificate"
  type        = list(string)
}

variable "client_domains" {
  type        = map(any) # string nundi any ki marchu
  description = "Dynamic app domains"
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted Zone ID of the ALB"
  type        = string
}

variable "verification_tokens" {
  description = "SES verification tokens for each client"
  type        = map(string)
}

variable "dkim_tokens" {
  description = "List of DKIM tokens for each client"
  type        = map(list(string))
}

variable "ses_mx_record" {
  description = "Regional SES MX record endpoint"
  type        = string
}

variable "mail_from_domains" {
  description = "Sub-domains for SES MAIL FROM configuration"
  type        = map(string)
}

# NEW: Variables for Static Domain Support
variable "static_client_configs" {
  description = "Map of static site configurations (S3 + CloudFront)"
  type        = map(any)
  default     = {}
}

variable "cloudfront_domain_names" {
  description = "CloudFront distribution domain names for static sites"
  type        = map(string)
  default     = {}
}

variable "cloudfront_hosted_zone_ids" {
  description = "CloudFront hosted zone IDs for Route53 alias records"
  type        = map(string)
  default     = {}
}

variable "main_domain" {
  description = "The primary domain for the infrastructure (e.g., webhizzy.in)"
  type        = string
  default     = ""
}

variable "mail_server_ip" {
  description = "The public IP of the primary mail server"
  type        = string
  default     = ""
}