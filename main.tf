# main.tf
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}

variable "placeholder_acm_arn" { default = "arn:aws:acm:us-east-1:123456789012:certificate/fake-arn" }

module "alb" {
  source                = "./modules/alb"
  project_name          = var.project_name
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  acm_certificate_arn   = var.placeholder_acm_arn # Will be replaced
}

module "ecs" {
  source       = "./modules/ecs"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  alb_sg_id    = module.alb.alb_sg_id
}