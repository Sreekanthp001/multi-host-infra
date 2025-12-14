resource "aws_iam_role" "ses_bounce_lambda_role" {
  name = "SES-Bounce-Handler-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "ses_bounce_lambda_policy" {
  name = "SES-Bounce-Handler-Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
        ]
        Effect = "Allow"
        Resource = "arn:aws:dynamodb:*:*:table/*" // భవిష్యత్ Suppression List టేబుల్ కోసం
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ses_bounce_policy_attach" {
  role       = aws_iam_role.ses_bounce_lambda_role.name
  policy_arn = aws_iam_policy.ses_bounce_lambda_policy.arn
}

resource "aws_lambda_function" "ses_bounce_handler" {
  filename         = "bounce_handler_lambda.zip"
  function_name    = "ses-bounce-complaint-handler"
  role             = aws_iam_role.ses_bounce_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 30
  source_code_hash = filebase64sha256("bounce_handler_lambda.js")
}

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