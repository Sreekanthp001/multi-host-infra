# modules/ecs/variables.tf
variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "alb_sg_id" { type = string }
variable "aws_region" { type = string }