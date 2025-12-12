output "verification_tokens" {
  description = "Map of domain key to SES verification token."
  value = {
    for k, v in aws_ses_domain_identity.client_ses_identity : k => v.verification_token
  }
}

output "dkim_tokens" {
  description = "Map of domain key to a list of DKIM tokens (3 required for CNAME records)."
  value = {
    for k, v in aws_ses_domain_dkim.client_ses_dkim : k => v.dkim_tokens
  }
}

output "ses_mx_record" {
  description = "MX record value pointing to the regional SES endpoint."
  value       = "10 inbound-smtp.${var.aws_region}.amazonaws.com"
}