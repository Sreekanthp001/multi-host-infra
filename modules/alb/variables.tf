# modules/alb/variables.tf

variable "project_name" {
  description = "The prefix used for naming resources"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the ALB will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "The ARN of the primary ACM certificate"
  type        = string
}

variable "acm_validation_resource" {
  description = "The validation object from the ACM module to enforce build order"
  type        = any 
}