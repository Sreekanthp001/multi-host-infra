# modules/client_deployment/variables.tf

variable "client_name" {
  type        = string
  description = "Name of the client (from each.key)"
}

variable "client_domains" {
  type        = map(string)
  description = "The domain mapping for this specific client"
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
  default = "vm-hosting"
}