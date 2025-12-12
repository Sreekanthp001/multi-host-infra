variable "client_domains" {
  description = "A map of client keys (e.g., 'sree84s') to their full domain names (e.g., 'sree84s.site')."
  type        = map(string)
}

variable "aws_region" {
  description = "The AWS region where SES is configured (e.g., us-east-1)."
  type        = string
}