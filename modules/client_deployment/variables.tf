variable "client_name" {
  type        = string
}

variable "domain_name" {
  type        = string
  description = "The main domain for this client (e.g., sree84s.site)"
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "ecs_cluster_id" {
  type = string
}

variable "task_definition_arn" {
  type = string
}

variable "ecs_service_security_group_id" {
  type = string
}

variable "alb_https_listener_arn" {
  type = string
}

variable "project_name" {
  type    = string
}

variable "priority_index" {
  type        = number
}