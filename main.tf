# main.tf (root - UPDATED)

# 1. Networking Module
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}

# 2. Route53 & ACM Module
module "route53_acm" {
  source       = "./modules/route53_acm"
  domain_names = ["venturemond.com", "sampleclient.com"] # Domains from variables.tf

  # Inputs from ALB (which is not yet applied, so we need to run apply twice)
  # The ALB's zone_id is a known constant, but we get the name dynamically.
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id # This will be added to ALB outputs
}

# 3. ALB Module
module "alb" {
  source              = "./modules/alb"
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  # CRITICAL: Pass the validated certificate ARN here
  acm_certificate_arn = module.route53_acm.acm_certificate_arn
}

# 4. ECS Cluster Module
module "ecs_cluster" {
  source       = "./modules/ecs"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  alb_sg_id    = module.alb.alb_sg_id
}