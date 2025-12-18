# 1. ADDED: project_name variable (Meeru root main.tf nundi idi pamputhunnaru kabatti thappakunda undali)
variable "project_name" {
  description = "A unique prefix for naming resources"
  type        = string
}

# 2. UPDATED: client_configs_map type
# 'any' vaadadam kante explicit type ivvadam best practice for debugging
variable "client_configs_map" {
  description = "The unified map of all client configurations."
  type = map(object({
    domain_name    = string
    hosting_type   = string
    email_accounts = list(string)
  }))
}

# 3. ALB 
variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted Zone ID of the Application Load Balancer (AWS managed)"
  type        = string
}

# 4. SES config
variable "verification_tokens" {
  description = "Map of client key to SES verification token"
  type        = map(string)
}

variable "dkim_tokens" {
  description = "Map of client key to a list of DKIM tokens"
  type        = map(list(string))
}

# 5. FIXED: ses_mx_record type
# Meeru 'string' ani icharu, kaani ses_config module nundi map vasthe idi 'map(string)' ga undali
variable "ses_mx_record" {
  description = "MX record value pointing to the regional SES endpoint"
  type        = string
  default     = "10 inbound-smtp.us-east-1.amazonaws.com." 
}

variable "mail_from_domains" {
  description = "Map of client domains to their SES MAIL FROM sub-domains"
  type        = map(string)
}