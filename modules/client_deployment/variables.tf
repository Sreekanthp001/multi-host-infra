# modules/client_deployment/variables.tf

variable "vpc_id" {
  description = "The VPC ID where the client target groups will be created"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs where ECS tasks will run"
  type        = list(string)
}

variable "client_domains" {
  description = "Map of client identifiers to their respective domain names"
  type        = map(string)
}

variable "ecs_cluster_id" {
  description = "The ID of the shared ECS Cluster"
  type        = string
}

variable "alb_https_listener_arn" {
  description = "The ARN of the HTTPS listener for routing rules"
  type        = string
}

variable "task_definition_arn" {
  description = "The ARN of the ECS task definition"
  type        = string
}

variable "ecs_service_security_group_id" {
  description = "Security group ID for the ECS service tasks"
  type        = string
}