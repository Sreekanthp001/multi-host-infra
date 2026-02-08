# root/variables.tf

variable "aws_region" {
  type    = string
}

variable "project_name" {
  type    = string
}

variable "vpc_cidr" {
  type    = string
}

variable "client_domains" {
  type    = map(string)
  description = "Dynamic app domains"
}

variable "static_client_configs" {
  type    = map(any)
  description = "Static site domains"
}

variable "forwarding_email" {
  type    = string
}