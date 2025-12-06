# modules/route53_acm/variables.tf

variable "domain_names" {
  description = "A list of client domain names to host and manage DNS/ACM for"
  type        = list(string)
  default     = ["venturemond.com", "sampleclient.com"] # The placeholder domains
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted Zone ID of the Application Load Balancer (AWS managed)"
  type        = string
}