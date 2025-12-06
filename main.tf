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
    aws = aws.us-east-1 # This tells the module to use the us_east_1 alias for ACM
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
  
  # Priority is essential for ALB Listener Rules (must be unique)
  priority = index(keys(var.client_domains), each.key) + 1 
  
  # 🔑 CRITICAL: INFRASTRUCTURE REFERENCES FROM OTHER MODULES
  # You must ensure these outputs exist in your respective modules (networking, alb, ecs, task_definition).

  # 1. Networking Inputs
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnets
  
  # 2. ALB/Listener Input
  # Assuming your ALB module outputs the HTTPS listener ARN.
  alb_https_listener_arn = module.alb.https_listener_arn 

  # 3. ECS Inputs
  ecs_cluster_id          = module.ecs.ecs_cluster_arn # Or .ecs_cluster_id
  
  # Assuming you have a security group defined specifically for ECS Fargate tasks in your networking/ecs module
  ecs_service_security_group_id = module.networking.ecs_service_security_group_id 
  
  # Assuming you have a separate module or resource for your Task Definition
  # If you create the Task Definition in the root or a separate module, reference its ARN here.
  task_definition_arn = module.task_definition.fargate_task_definition_arn 
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