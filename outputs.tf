output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "client_smtp_secrets" {
  description = "Individual SMTP credentials for each client"
  value       = module.ses_config.client_smtp_secrets
  sensitive   = true
}