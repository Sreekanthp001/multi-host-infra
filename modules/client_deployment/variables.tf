// Remove 'client_domains' variable definition if it exists in this file.
// The module now receives specific client data via 'for_each'.

variable "client_id" {
  description = "The unique identifier for the client being deployed (e.g., sree84s-prod)."
  type        = string
}

variable "domain_name" {
  description = "The root domain name for the client website."
  type        = string
}

variable "docker_image_tag" {
  description = "The Docker image tag to deploy for this client's ECS service."
  type        = string
}

// -------------------------------------------------------------
// Infrastructure Inputs (These should already be defined)
// -------------------------------------------------------------
variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnet IDs."
  type        = list(string)
}

variable "alb_https_listener_arn" {
  description = "The ARN of the ALB HTTPS Listener."
  type        = string
}

variable "ecs_cluster_id" {
  description = "The ID of the shared ECS cluster."
  type        = string
}

variable "ecs_service_security_group_id" {
  description = "The Security Group ID for ECS tasks."
  type        = string
}

variable "task_definition_arn" {
  description = "The ARN of the base ECS Task Definition."
  type        = string
}

variable "listener_priority" {
  description = "The priority number for the ALB listener rule (1 to 50000)."
  type        = number
}