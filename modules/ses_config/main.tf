data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


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
  for_each            = var.client_domains
  name                = "${each.key}-forwarding-rule"
  rule_set_name       = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
  enabled             = true
  scan_enabled        = true

  recipients          = ["@${each.value}"]

  depends_on = [
    aws_s3_bucket_policy.ses_s3_delivery_policy,
    aws_ses_receipt_rule_set.main_rule_set
  ]

  s3_action {
    bucket_name = aws_s3_bucket.ses_inbound_bucket.id
    position    = 1 
  }
}

resource "aws_ses_domain_mail_from" "client_mail_from" {
  for_each          = var.client_domains
  domain            = aws_ses_domain_identity.client_ses_identity[each.key].domain 
  
  mail_from_domain = "mail.${each.value}" 
}

output "mail_from_domains" {
  description = "The Mail From domains configured for SES"
  
  value       = { for k, v in aws_ses_domain_mail_from.client_mail_from : k => v.mail_from_domain }
}

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

resource "aws_iam_user" "smtp_user" {
  name = "ses-smtp-user"
  tags = {
    Purpose = "SES_SMTP_Access"
  }
}

resource "aws_iam_user_policy_attachment" "ses_smtp_attachment" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.ses_send_policy.arn
}


resource "aws_iam_access_key" "smtp_access_key" {
  user   = aws_iam_user.smtp_user.name
  status = "Active"
}

output "smtp_username" {
  description = "The Access Key ID for SES SMTP (Username)"
  value       = aws_iam_access_key.smtp_access_key.id
  sensitive   = true 
}

output "smtp_password" {
  description = "The Secret Access Key for SES SMTP (Password)"
  value       = aws_iam_access_key.smtp_access_key.secret
  sensitive   = true 
}

# S3 బకెట్ రిసోర్స్
resource "aws_s3_bucket" "ses_inbound_bucket" {
  bucket = "sree84s-ses-inbound-mail-storage-0102" 
  acl    = "private"

  lifecycle_rule {
    enabled = true
    id      = "cleanup"
    expiration {
      days = 90
    }
  }
}

# 🛑 పరిష్కారం: SES కు PutObject అనుమతి ఇవ్వడానికి బకెట్ పాలసీని సరిచేయడం
resource "aws_s3_bucket_policy" "ses_s3_delivery_policy" {
  bucket = aws_s3_bucket.ses_inbound_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action = "s3:PutObject" 
        Resource = "${aws_s3_bucket.ses_inbound_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" : "535462128585",
            # 🛑 పరిష్కారం: ARN ను స్ట్రింగ్ interpolation లో ఇవ్వడం వలన JSON లో సరైన ఫార్మాట్ అవుతుంది.
            "aws:SourceArn" : "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/multi-client-rules"
          }
        }
      },
    ]
  })
}