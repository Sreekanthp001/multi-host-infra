# modules/ses_config/bounce_handler.tf
data "archive_file" "bounce_zip" {
  type        = "zip"
  source_file = "${path.root}/lambda/bounce_handler_lambda.js"
  output_path = "${path.module}/bounce_handler_lambda.zip"
}
# 1. IAM Role for Bounce Handler Lambda
resource "aws_iam_role" "ses_bounce_lambda_role" {
  name = "${var.project_name}-ses-bounce-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 2. Basic Logging Policy
resource "aws_iam_role_policy_attachment" "bounce_log_attach" {
  role       = aws_iam_role.ses_bounce_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. Bounce Handler Lambda Function
resource "aws_lambda_function" "ses_bounce_handler" {
  filename         = data.archive_file.bounce_zip.output_path
  function_name    = "${var.project_name}-ses-bounce-complaint-handler"
  role             = aws_iam_role.ses_bounce_lambda_role.arn
  handler          = "bounce_handler_lambda.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.bounce_zip.output_base64sha256
}

# 4. Permissions for SNS to trigger Lambda
resource "aws_lambda_permission" "allow_sns_bounce" {
  statement_id  = "AllowExecutionFromSNSBounce"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ses_bounce_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ses_bounce_topic.arn
}

resource "aws_lambda_permission" "allow_sns_complaint" {
  statement_id  = "AllowExecutionFromSNSComplaint"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ses_bounce_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ses_complaint_topic.arn
}

# 5. SNS Subscriptions
resource "aws_sns_topic_subscription" "bounce_subscription" {
  topic_arn = aws_sns_topic.ses_bounce_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ses_bounce_handler.arn
}

resource "aws_sns_topic_subscription" "complaint_subscription" {
  topic_arn = aws_sns_topic.ses_complaint_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ses_bounce_handler.arn
}

# modules/ses_config/bounce_handler.tf lo last lo idi add chey mawa

# 6. SNS Topics for SES Notifications
resource "aws_sns_topic" "ses_bounce_topic" {
  name = "${var.project_name}-ses-bounce-topic"
}

resource "aws_sns_topic" "ses_complaint_topic" {
  name = "${var.project_name}-ses-complaint-topic"
}

# 7. SES Identity Notification Setups (Corrected with for_each)
resource "aws_ses_identity_notification_topic" "bounce" {
  for_each                 = var.client_domains # Loop through all domains
  topic_arn                = aws_sns_topic.ses_bounce_topic.arn
  notification_type        = "Bounce"
  identity                 = aws_ses_domain_identity.client_ses_identity[each.key].domain
}

resource "aws_ses_identity_notification_topic" "complaint" {
  for_each                 = var.client_domains # Loop through all domains
  topic_arn                = aws_sns_topic.ses_complaint_topic.arn
  notification_type        = "Complaint"
  identity                 = aws_ses_domain_identity.client_ses_identity[each.key].domain
}