# modules/monitoring/main.tf
# CloudWatch Alarms for Production Monitoring
# Addresses: Manager's Requirement #6 - Observability

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
  
  tags = {
    Name        = "${var.project_name}-alerts"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ============================================================================
# ECS MONITORING
# ============================================================================

# 1. ECS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each = var.client_domains
  
  alarm_name          = "${var.project_name}-${each.key}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "ECS CPU utilization is too high for ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "${var.project_name}-${each.key}-svc"
  }
  
  tags = {
    Client      = each.key
    Environment = "Production"
  }
}

# 2. ECS Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  for_each = var.client_domains
  
  alarm_name          = "${var.project_name}-${each.key}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "ECS memory utilization is too high for ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "${var.project_name}-${each.key}-svc"
  }
  
  tags = {
    Client      = each.key
    Environment = "Production"
  }
}

# 3. ECS Service Running Task Count
resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks_low" {
  for_each = var.client_domains
  
  alarm_name          = "${var.project_name}-${each.key}-ecs-tasks-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "ECS running task count is too low for ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "breaching"
  
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "${var.project_name}-${each.key}-svc"
  }
  
  tags = {
    Client      = each.key
    Environment = "Production"
  }
}

# ============================================================================
# ALB MONITORING
# ============================================================================

# 4. ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "ALB is returning too many 5xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  
  tags = {
    Environment = "Production"
  }
}

# 5. ALB 4xx Errors (High Rate)
resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors_high" {
  alarm_name          = "${var.project_name}-alb-4xx-errors-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "ALB is returning too many 4xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  
  tags = {
    Environment = "Production"
  }
}

# 6. ALB Unhealthy Target Count
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  for_each = var.client_domains
  
  alarm_name          = "${var.project_name}-${each.key}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Unhealthy targets detected for ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix[each.key]
  }
  
  tags = {
    Client      = each.key
    Environment = "Production"
  }
}

# 7. ALB Response Time
resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  alarm_name          = "${var.project_name}-alb-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"  # 2 seconds
  alarm_description   = "ALB response time is too high"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  
  tags = {
    Environment = "Production"
  }
}

# ============================================================================
# SES MONITORING
# ============================================================================

# 8. SES Bounce Rate
resource "aws_cloudwatch_metric_alarm" "ses_bounce_rate" {
  for_each = var.client_domains
  
  alarm_name          = "${var.project_name}-${each.key}-ses-bounce-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Reputation.BounceRate"
  namespace           = "AWS/SES"
  period              = "3600"
  statistic           = "Average"
  threshold           = "0.05"  # 5% bounce rate
  alarm_description   = "SES bounce rate is too high for ${each.key} - Risk of account suspension"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    Domain = each.value.domain
  }
  
  tags = {
    Client      = each.key
    Environment = "Production"
  }
}

# 9. SES Complaint Rate
resource "aws_cloudwatch_metric_alarm" "ses_complaint_rate" {
  for_each = var.client_domains
  
  alarm_name          = "${var.project_name}-${each.key}-ses-complaint-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Reputation.ComplaintRate"
  namespace           = "AWS/SES"
  period              = "3600"
  statistic           = "Average"
  threshold           = "0.001"  # 0.1% complaint rate
  alarm_description   = "SES complaint rate is too high for ${each.key} - Risk of account suspension"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    Domain = each.value.domain
  }
  
  tags = {
    Client      = each.key
    Environment = "Production"
  }
}

# 10. SES Daily Sending Quota
resource "aws_cloudwatch_metric_alarm" "ses_sending_quota" {
  alarm_name          = "${var.project_name}-ses-sending-quota"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Send"
  namespace           = "AWS/SES"
  period              = "86400"  # 24 hours
  statistic           = "Sum"
  threshold           = "40000"  # 80% of 50,000 default quota
  alarm_description   = "Approaching SES daily sending quota - Request limit increase"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  tags = {
    Environment = "Production"
  }
}

# ============================================================================
# CLOUDFRONT MONITORING (for static sites)
# ============================================================================

# 11. CloudFront 4xx Error Rate
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  for_each = var.static_client_configs
  
  alarm_name          = "${var.project_name}-${each.key}-cloudfront-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"  # 5% error rate
  alarm_description   = "CloudFront 4xx error rate is too high for ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    DistributionId = var.cloudfront_distribution_ids[each.key]
  }
  
  tags = {
    Client      = each.key
    Environment = "Production"
  }
}

# 12. CloudFront 5xx Error Rate
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_errors" {
  for_each = var.static_client_configs
  
  alarm_name          = "${var.project_name}-${each.key}-cloudfront-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"  # 1% error rate
  alarm_description   = "CloudFront 5xx error rate is too high for ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    DistributionId = var.cloudfront_distribution_ids[each.key]
  }
  
  tags = {
    Client      = each.key
    Environment = "Production"
  }
}

# ============================================================================
# LAMBDA MONITORING (SES Bounce Handler)
# ============================================================================

# 13. Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-ses-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Lambda function is experiencing errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = var.lambda_function_name
  }
  
  tags = {
    Environment = "Production"
  }
}

# 14. Lambda Throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-lambda-ses-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Lambda function is being throttled"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = var.lambda_function_name
  }
  
  tags = {
    Environment = "Production"
  }
}

# ============================================================================
# COMPOSITE ALARMS (Advanced)
# ============================================================================

# 15. Service Health Composite Alarm (per client)
resource "aws_cloudwatch_composite_alarm" "service_health" {
  for_each = var.client_domains
  
  alarm_name          = "${var.project_name}-${each.key}-service-health"
  alarm_description   = "Composite alarm for overall service health of ${each.key}"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.ecs_cpu_high[each.key].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.ecs_memory_high[each.key].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.alb_unhealthy_targets[each.key].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.ses_bounce_rate[each.key].alarm_name})",
  ])
  
  tags = {
    Client      = each.key
    Environment = "Production"
  }
}
