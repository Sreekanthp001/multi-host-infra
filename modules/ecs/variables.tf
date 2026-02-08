# modules/ecs/variables.tf

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string 
}

variable "vpc_id" { 
  description = "VPC ID where the security group will be created"
  type        = string 
}

variable "alb_sg_id" {
  description = "The security group ID of the ALB to allow inbound traffic"
  type        = string 
}

variable "aws_region" {
  description = "AWS region for CloudWatch logs"
  type        = string 
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "secret_arns" {
  description = "Map of secret ARNs for client applications"
  type        = map(string)
  default     = {}
}
