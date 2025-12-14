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

resource "aws_ses_domain_mail_from" "client_mail_from" {
  for_each         = var.client_domains
  domain           = aws_ses_domain_identity.client_ses_identity[each.key].domain 
  mail_from_domain = "mail.${each.value}" 
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

resource "aws_s3_bucket" "ses_inbound_bucket" {
  bucket = "sree84s-ses-inbound-mail-storage-0102"
}

resource "aws_s3_bucket_public_access_block" "ses_bucket_block" {
  bucket = aws_s3_bucket.ses_inbound_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "ses_s3_delivery_policy" {
  bucket = aws_s3_bucket.ses_inbound_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action   = "s3:PutObject" 
        Resource = "${aws_s3_bucket.ses_inbound_bucket.arn}/*", 
      },
    ]
  })
}

resource "aws_sns_topic" "ses_notification_topic" {
  name = "vm-hosting-ses-notification-topic"
}

resource "aws_ses_receipt_rule_set" "main_rule_set" {
  rule_set_name = "multi-client-rules"

  depends_on = [
    aws_ses_domain_identity.client_ses_identity
  ]
}

resource "aws_ses_receipt_rule" "forwarding_rule" {
  for_each      = var.client_domains
  name          = "${each.key}-forwarding-rule"
  rule_set_name = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
  enabled       = true
  scan_enabled  = true

  recipients = [each.value] 

  depends_on = [
    aws_s3_bucket_policy.ses_s3_delivery_policy 
  ]
  
  s3_action {
    bucket_name = aws_s3_bucket.ses_inbound_bucket.id
    position    = 1 
  }

  sns_action {
    position    = 2
    topic_arn   = aws_sns_topic.ses_notification_topic.arn
  }
}

resource "aws_sns_topic" "ses_bounce_topic" {
  name = "ses-bounce-notifications-topic"
}

resource "aws_sns_topic" "ses_complaint_topic" {
  name = "ses-complaint-notifications-topic"
}

resource "aws_ses_identity_notification_topic" "client_bounce_topic" {
  for_each          = aws_ses_domain_identity.client_ses_identity
  identity          = each.value.domain
  notification_type = "Bounce"
  topic_arn         = aws_sns_topic.ses_bounce_topic.arn
}

resource "aws_ses_identity_notification_topic" "client_complaint_topic" {
  for_each          = aws_ses_domain_identity.client_ses_identity
  identity          = each.value.domain
  notification_type = "Complaint"
  topic_arn         = aws_sns_topic.ses_complaint_topic.arn
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

output "mail_from_domains" {
  description = "The Mail From domains configured for SES"
  value       = { for k, v in aws_ses_domain_mail_from.client_mail_from : k => v.mail_from_domain }
}