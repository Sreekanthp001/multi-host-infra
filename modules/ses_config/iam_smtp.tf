# 1. Create the IAM User for SMTP
resource "aws_iam_user" "smtp_user" {
  name = "${var.project_name}-ses-smtp-user"
}

# 2. Attach policy to allow sending emails via SES
resource "aws_iam_user_policy" "smtp_policy" {
  name = "AmazonSesSendingPolicy"
  user = aws_iam_user.smtp_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ses:SendRawEmail"
        Resource = "*"
      }
    ]
  })
}

# 3. Create Access Key and Secret Key (SMTP Credentials)
resource "aws_iam_access_key" "smtp_access_key" {
  user = aws_iam_user.smtp_user.name
}

# 4. Create the Secrets Manager entry
resource "aws_secretsmanager_secret" "ses_smtp_credentials" {
  name        = "${var.project_name}/ses-smtp-credentials"
  description = "SMTP credentials for sending emails via SES"
}

# 5. Store the actual SMTP password in Secrets Manager
resource "aws_secretsmanager_secret_version" "ses_smtp_credentials_version" {
  secret_id = aws_secretsmanager_secret.ses_smtp_credentials.id
  secret_string = jsonencode({
    SMTP_USER     = aws_iam_access_key.smtp_access_key.id
    # IMPORTANT: .ses_smtp_password_v4 converts IAM Secret into SES SMTP Password
    SMTP_PASSWORD = aws_iam_access_key.smtp_access_key.ses_smtp_password_v4 
    SMTP_HOST     = "email-smtp.${data.aws_region.current.name}.amazonaws.com"
    SMTP_PORT     = "587"
  })
}