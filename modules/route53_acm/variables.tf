# modules/route53_acm/variables.tf

variable "domain_names" {
  description = "List of all domain names to include in the SSL certificate"
  type        = list(string)
}

variable "client_domains" {
  description = "Map of client keys to root domain names"
  type        = map(string)
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