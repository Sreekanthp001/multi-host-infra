resource "aws_iam_role" "ses_forwarder_role" {
  name = "${var.project_name}-ses-forwarder-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "ses_forwarder_policy" {
  name        = "${var.project_name}-ses-forwarder-policy"
  description = "Policy for SES forwarder lambda to read S3 and send via SES"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
        Effect   = "Allow"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.ses_inbound_bucket.arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action = "ses:SendRawEmail"
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ses_forwarder_attach" {
  role       = aws_iam_role.ses_forwarder_role.name
  policy_arn = aws_iam_policy.ses_forwarder_policy.arn
}