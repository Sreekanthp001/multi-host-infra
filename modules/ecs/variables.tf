# modules/ecs/variables.tf
variable "project_name" {
     type = string 
}
variable "vpc_id" { 
    type = string 
}

variable "alb_sg_id" {
    type = string 
}

variable "aws_region" {
    type = string 
}
variable "ecr_repository_url" {
  description = "The URL of the ECR repository where the Docker image is stored."
  type        = string
}