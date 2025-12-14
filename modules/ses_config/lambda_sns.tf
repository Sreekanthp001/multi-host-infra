resource "aws_sns_topic" "ses_notification_topic" {
  name = "${var.project_name}-ses-notification-topic"
}

resource "aws_lambda_function" "ses_forwarder_lambda" {
  filename         = "${path.module}/forward_lambda_code.zip"
  function_name    = "${var.project_name}-ses-forwarder-lambda"
  role             = aws_iam_role.ses_forwarder_role.arn
  handler          = "forward_lambda_code.handler"
  runtime          = "nodejs16.x"
  timeout          = 30
  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/forward_lambda_code.js"
  output_path = "${path.module}/forward_lambda_code.zip"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.ses_notification_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ses_forwarder_lambda.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ses_forwarder_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ses_notification_topic.arn
}