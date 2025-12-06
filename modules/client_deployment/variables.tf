# modules/client_deployment/variables.tf

variable "vpc_id" {
  description = "The VPC ID where the client resources will be placed."
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for ECS tasks."
  type        = list(string)
}
variable "client_domains" {
  description = "Map of client names (key) to their root domain names (value) used for dynamic resource creation."
  type        = map(string)
}

variable "ecs_cluster_id" {
  description = "The ARN/ID of the shared ECS cluster."
  type        = string
}

variable "alb_https_listener_arn" {
  description = "The ARN of the shared HTTPS listener (port 443) on the ALB."
  type        = string
}

variable "task_definition_arn" {
  description = "The ARN of the ECS task definition to deploy for this client."
  type        = string
}

variable "ecs_service_security_group_id" {
  description = "The ID of the Security Group to apply to the ECS tasks."
  type        = string
}