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
  value = "10 inbound-smtp.us-east-1.amazonaws.com." # Or your dynamic logic
}

output "client_smtp_secrets" {
  description = "Individual SMTP credentials for each client"
  value = {
    for k, v in aws_iam_access_key.smtp_key : k => {
      smtp_username = v.id
      smtp_password = v.ses_smtp_password_v4
    }
  }
  sensitive = true # Passwords kabatti hide chesthundhi
}