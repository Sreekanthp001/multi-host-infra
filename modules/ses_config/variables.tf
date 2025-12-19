variable "project_name"     { type = string }
variable "aws_region"       { type = string }
variable "forwarding_email" { type = string }
variable "client_configs_map" {
  type = map(object({
    domain_name    = string
    hosting_type   = string
    email_accounts = list(string)
  }))
}