variable "project_name" { type = string }
variable "aws_region"   { type = string }
variable "forwarding_email" { type = string }

# Root lo pass chesthunnav kabatti idhi kachithanga undali
variable "all_client_domains" {
  type    = list(string)
  default = []
}

# Idhi for_each logic kosam
variable "client_configs_map" {
  type = map(object({
    domain_name    = string
    hosting_type   = string
    email_accounts = list(string)
  }))
}

# Root main.tf lo pampistunnav kabatti idhi kuda pettu
variable "client_domains" {
  type = map(string)
}