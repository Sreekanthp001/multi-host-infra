# modules/route53_acm/variables.tf

variable "domain_names" {
  description = "A list of client domain names to host and manage DNS/ACM for"
  type        = list(string)
  default     = ["sree84s.site"] # The placeholder domains
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted Zone ID of the Application Load Balancer (AWS managed)"
  type        = string
}

variable "client_domains" {
  description = "Map of client names (key) to their root domain names (value). This list drives all infrastructure creation."
  type = map(string)
  default = {
    my_test_client = "sree84s.site"
  }
}