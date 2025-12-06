# main.tf (root - CORRECTED)

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}
module "route53_acm" {
  source       = "./modules/route53_acm"
  domain_names = ["venturemond.com", "sampleclient.com"] 

  # Pass the aliased provider configuration into the module
  providers = {
    aws = aws.us_east_1 # This tells the module to use the us_east_1 alias for ACM
  }

  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

# 3. ALB Module
module "alb" {
  source              = "./modules/alb"
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  acm_certificate_arn = module.route53_acm.acm_certificate_arn
}

# 4. ECS Cluster Module
module "ecs_cluster" {
  source       = "./modules/ecs"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  alb_sg_id    = module.alb.alb_sg_id
}