# modules/waf/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer to protect"
  type        = string
}
