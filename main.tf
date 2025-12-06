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
# main.tf (Root Directory)

# 6. Deploy Each Client Website (Scalable Loop)
# This module iterates over the client_domains map defined in variables.tf
module "client_deployment" {
  for_each = var.client_domains 
  source   = "./modules/client_deployment"

  # Inputs derived from the for_each loop
  client_name = each.key         # e.g., "client_a"
  domain_name = each.value       # e.g., "venturemond.com"
  priority    = index(keys(var.client_domains), each.key) + 1 
  
    # 1. Networking Inputs
  vpc_id          = module.networking.vpc_id
  # Check module.networking/outputs.tf for the exact name
  private_subnets = module.networking.private_subnets_list 
  
  # 2. ALB/Listener Input
  # Check module.alb/outputs.tf for the exact name
  alb_https_listener_arn = module.alb.https_listener_arn 

  # 3. ECS Inputs
  # ERROR FIX: If your module call is 'module.ecs_cluster', use that name.
  ecs_cluster_id          = module.ecs_cluster.ecs_cluster_arn 
  
  # Check module.networking/outputs.tf or module.alb/outputs.tf for the exact name
  ecs_service_security_group_id = module.networking.ecs_tasks_security_group_id
  
  # ERROR FIX: Assuming you create a separate module for the task definition
  # You must declare this module call elsewhere in main.tf first.
  task_definition_arn = module.ecs_task_definition.fargate_task_definition_arn 
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