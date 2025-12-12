# modules/route53_acm/variables.tf

variable "domain_names" {
  description = "A list of client domain names to host and manage DNS/ACM for"
  type        = list(string)
}


variable "client_domains" {
  description = "Map of client keys (e.g., 'sree84s') to their root domain names (value). This list drives all infrastructure creation."
  type        = map(string)
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
  description = "Map of client key to SES verification token (from ses_config module output)."
  type        = map(string)
}

variable "dkim_tokens" {
  description = "Map of client key to a list of DKIM tokens for CNAME records (from ses_config module output)."
  
  type        = map(list(string))
}

variable "ses_mx_record" {
  description = "MX record value pointing to the regional SES endpoint (from ses_config module output)."
  type        = string
}

variable "mail_from_domains" {
  description = "Map of client domains to their configured SES MAIL FROM sub-domains (e.g. mail.sree84s.site)"
  type        = map(string)
}