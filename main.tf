# main.tf (root - CORRECTED)

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}
module "route53_acm" {
  source       = "./modules/route53_acm"
  domain_names = values(var.client_domains) 

  # Pass the aliased provider configuration into the module
  providers = {
    aws = aws.us_east_1 # This tells the module to use the us_east_1 alias for ACM
  }

  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

# 6. Deploy Each Client Website
# This loop scales for all 70-100 clients defined in var.client_domains
module "client_deployment" {
  for_each = var.client_domains
  source   = "./modules/client_deployment"
  
  client_name = each.key         # e.g., client_a
  domain_name = each.value       # e.g., venturemond.com
  priority    = index(keys(var.client_domains), each.key) + 10 
  # ... (other variables) ...
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