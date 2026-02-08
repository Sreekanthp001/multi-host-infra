# modules/ses_config/outputs.tf

output "verification_tokens" {
  description = "SES verification tokens for each domain"
  value       = { for k, v in aws_ses_domain_identity.client_ses_identity : k => v.verification_token }
}

output "dkim_tokens" {
  description = "DKIM tokens for DNS CNAME records"
  value       = { for k, v in aws_ses_domain_dkim.client_ses_dkim : k => v.dkim_tokens }
}

output "ses_mx_record" {
  description = "Regional SES MX endpoint"
  value       = "inbound-smtp.${data.aws_region.current.name}.amazonaws.com"
}

output "mail_from_domains" {
  value = { for k, v in aws_ses_domain_mail_from.client_mail_from : k => v.mail_from_domain }
}