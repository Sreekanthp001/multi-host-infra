# modules/ses_config/main.tf

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# SES Domain Identity for each client
resource "aws_ses_domain_identity" "client_ses_identity" {
  for_each = var.client_domains
  domain   = each.value.domain
}

# DKIM for email authentication
resource "aws_ses_domain_dkim" "client_ses_dkim" {
  for_each = var.client_domains
  domain   = aws_ses_domain_identity.client_ses_identity[each.key].domain
}

# MAIL FROM setup for better deliverability
resource "aws_ses_domain_mail_from" "client_mail_from" {
  for_each         = var.client_domains
  domain           = aws_ses_domain_identity.client_ses_identity[each.key].domain 
  mail_from_domain = "mail.${each.value.domain}" 
}

# S3 Bucket for inbound mail storage
resource "aws_s3_bucket" "ses_inbound_bucket" {
  bucket        = "${var.project_name}-ses-inbound-storage-2026"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "ses_bucket_block" {
  bucket = aws_s3_bucket.ses_inbound_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow SES to write to the S3 bucket
resource "aws_s3_bucket_policy" "ses_s3_delivery_policy" {
  bucket = aws_s3_bucket.ses_inbound_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ses.amazonaws.com" }
        Action    = "s3:PutObject" 
        Resource  = "${aws_s3_bucket.ses_inbound_bucket.arn}/*"
        Condition = {
          StringEquals = { "aws:Referer" = data.aws_caller_identity.current.account_id }
        }
      },
    ]
  })
}

# SES Receipt Rules
resource "aws_ses_receipt_rule_set" "main_rule_set" {
  rule_set_name = "${var.project_name}-rule-set"
}

# Lambda Permission for SES to invoke the bounce handler
resource "aws_lambda_permission" "allow_ses_invoke" {
  statement_id  = "AllowExecutionFromSES"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ses_bounce_handler.function_name
  principal     = "ses.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_ses_receipt_rule" "forwarding_rule" {
  for_each      = var.client_domains
  name          = "${each.key}-forward-rule"
  rule_set_name = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
  enabled       = true
  recipients    = [each.value.domain]

  s3_action {
    bucket_name = aws_s3_bucket.ses_inbound_bucket.id
    position    = 1
  }

  lambda_action {
    function_arn = aws_lambda_function.ses_bounce_handler.arn
    position     = 2
    invocation_type = "Event"
  }

  depends_on = [
    aws_s3_bucket_policy.ses_s3_delivery_policy,
    aws_lambda_permission.allow_ses_invoke
  ]
}