resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "Cloud-Email-Infrastructure-V2"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "text",
      "x": 0, "y": 0, "width": 24, "height": 3,
      "properties": {
        "markdown": "# 📧 Multi-Tenant Email Infrastructure Dashboard\nMonitoring SES and Forwarding Lambda for all clients."
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 3, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/SES", "Send", "Service", "SES" ],
          [ ".", "Reject", ".", "." ],
          [ ".", "Bounce", ".", "." ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "Overall SES Statistics (Sends/Rejects/Bounces)"
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 3, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "Invocations", "FunctionName", "vm-hosting-ses-forwarder-lambda" ],
          [ ".", "Errors", ".", "." ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "Forwarding Lambda Performance"
      }
    },
    {
        "type": "log",
        "x": 0, "y": 9, "width": 24, "height": 6,
        "properties": {
          "query": "SOURCE '/aws/lambda/vm-hosting-ses-forwarder-lambda' | fields @timestamp, @message | filter @message like /SUCCESS/ | sort @timestamp desc | limit 20",
          "region": "us-east-1",
          "title": "Recent Successful Forwardings (Client Tracking)"
        }
      }
  ]
}
EOF
}

output "dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=Cloud-Email-Infrastructure-V2"
}