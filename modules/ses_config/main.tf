resource "aws_ses_domain_identity" "client_ses_identity" {
  for_each = var.client_domains
  domain   = each.value
}

resource "aws_ses_domain_dkim" "client_ses_dkim" {
  for_each = var.client_domains
  domain   = aws_ses_domain_identity.client_ses_identity[each.key].domain
}

resource "aws_ses_receipt_rule_set" "main_rule_set" {
  rule_set_name = "multi-client-rules"

  depends_on = [
    aws_ses_domain_identity.client_ses_identity
  ]
}

resource "aws_ses_receipt_rule" "forwarding_rule" {
  for_each        = var.client_domains
  name            = "${each.key}-forwarding-rule"
  rule_set_name   = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
  enabled         = true
  scan_enabled    = true

  recipients      = [each.value]
}

# SES Custom MAIL FROM (FIXED: Using each.value (domain name) instead of each.key (client key))
resource "aws_ses_domain_mail_from" "client_mail_from" {
  for_each         = var.client_domains
  domain           = aws_ses_domain_identity.client_ses_identity[each.key].domain 
  # FIX: ఇక్కడ each.key కు బదులు each.value ను ఉపయోగించండి.
  mail_from_domain = "mail.${each.value}" 
}

output "mail_from_domains" {
  description = "The Mail From domains configured for SES"
  # FIX: ఇక్కడ కూడా each.value ను ఉపయోగించండి.
  value       = { for k, v in aws_ses_domain_mail_from.client_mail_from : k => v.mail_from_domain }
}

# 1. SES Send-Only Policy ని సృష్టించడం
resource "aws_iam_policy" "ses_send_policy" {
  name        = "SES_SMTP_Send_Access"
  description = "Allows sending email via SES in the current region"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ses:SendRawEmail"
        Resource = "*"
      },
    ]
  })
}

# 2. SMTP User ను సృష్టించడం
resource "aws_iam_user" "smtp_user" {
  name = "ses-smtp-user"
  # ఈ యూజర్ కేవలం ప్రోగ్రామాటిక్ యాక్సెస్ కోసం.
  tags = {
    Purpose = "SES_SMTP_Access"
  }
}

# 3. Policy ని User కి జత చేయడం
resource "aws_iam_user_policy_attachment" "ses_smtp_attachment" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.ses_send_policy.arn
}

# 4. Access Key ను సృష్టించడం (ఇదే SMTP Username)
resource "aws_iam_access_key" "smtp_access_key" {
  user    = aws_iam_user.smtp_user.name
  # స్థితిని Active గా ఉంచండి
  status  = "Active"
}

# 5. అవుట్‌పుట్‌లు (SMTP Username మరియు Secret/Password)
# NOTE: Secret Key ను state file లో సేవ్ చేయడం మంచి పద్ధతి కాదు, కానీ Terraform లో తప్పదు.
# దీన్ని జాగ్రత్తగా నిర్వహించండి.
output "smtp_username" {
  description = "The Access Key ID for SES SMTP (Username)"
  value       = aws_iam_access_key.smtp_access_key.id
  sensitive   = true # ఈ అవుట్‌పుట్‌ను ప్లాన్/అప్లై అవుట్‌పుట్‌లో దాచండి
}

output "smtp_password" {
  description = "The Secret Access Key for SES SMTP (Password)"
  value       = aws_iam_access_key.smtp_access_key.secret
  sensitive   = true # ఈ అవుట్‌పుట్‌ను ప్లాన్/అప్లై అవుట్‌పుట్‌లో దాచండి
}