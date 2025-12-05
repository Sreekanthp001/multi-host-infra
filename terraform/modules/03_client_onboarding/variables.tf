variable "project_name" {
  description = "Project name prefix."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "client_name" {
  type = string
}
variable "alb_zone_id" {
  type = string
}

variable "domain_name" {
  description = "The client's domain name (e.g., example.com)."
  type        = string
}

variable "site_type" {
  description = "Type of hosting: 'static' (S3/CF) or 'fargate' (ECS/ALB)."
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate to use for SSL/TLS."
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the central Application Load Balancer."
  type        = string
  default     = null
}

# Used for ECS Fargate deployment (optional for static sites)
variable "alb_listener_arn" {
  description = "ARN of the ALB HTTPS Listener (to add the rule to)."
  type        = string
  default     = null
}

variable "ecs_cluster_id" {
  description = "ID of the ECS cluster."
  type        = string
  default     = null
}

variable "ecs_tasks_sg_id" {
  description = "Security Group ID for ECS tasks."
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Fargate tasks."
  type        = list(string)
  default     = []
}