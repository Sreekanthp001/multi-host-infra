# modules/monitoring/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "client_domains" {
  description = "Map of client domains for dynamic hosting"
  type        = map(any)
}

variable "static_client_configs" {
  description = "Map of static client configurations"
  type        = map(any)
  default     = {}
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch metrics"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Map of target group ARN suffixes per client"
  type        = map(string)
}

variable "cloudfront_distribution_ids" {
  description = "Map of CloudFront distribution IDs for static sites"
  type        = map(string)
  default     = {}
}

variable "lambda_function_name" {
  description = "Name of the SES bounce handler Lambda function"
  type        = string
}
