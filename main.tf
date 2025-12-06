# main.tf (Root Directory - FINAL CORRECTED VERSION)

# 1. Networking Module
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}

# 2. ALB Module (Requires Networking outputs and ACM ARN)
module "alb" {
  source              = "./modules/alb"
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids # Check outputs.tf for exact name
  
  # 🔑 FIX: Provide the required ACM ARN argument, referencing the output of the ACM module
  acm_certificate_arn = module.route53_acm.acm_certificate_arn 
}

# 3. ECS Cluster Module (Includes Cluster, Task Definition, and SG logic)
module "ecs_cluster" {
  source       = "./modules/ecs"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  alb_sg_id    = module.alb.alb_sg_id # Check outputs.tf for exact name
}

# 4. Route53/ACM Module (Runs in us-east-1, depends on ALB outputs)
module "route53_acm" {
  source       = "./modules/route53_acm"
  domain_names = values(var.client_domains)

  providers = {
    aws = aws.us_east_1
  }

  # These outputs come from module.alb
  alb_dns_name = module.alb.alb_dns_name 
  alb_zone_id  = module.alb.alb_zone_id
  
  # 🔑 ACTION: Ensure module.route53_acm/outputs.tf contains 'acm_certificate_arn'
}

# 5. Deploy Each Client Website (Scalable Loop)
# main.tf (FINAL CORRECTIONS ON DEPENDENCIES)

# ... (rest of your root main.tf code) ...

# 5. Deploy Each Client Website (Scalable Loop)
module "client_deployment" {
  for_each = var.client_domains
  source   = "./modules/client_deployment"

  # ... other inputs (client_name, domain_name, priority, vpc_id, private_subnets) ...

  # 1. ALB/Listener Input (FIXED: Uses the exact name you provided in your outputs.tf)
  alb_https_listener_arn = module.alb.alb_https_listener_arn 

  # 2. ECS Inputs (FIXED: Uses the exact names you provided in your outputs.tf)
  ecs_cluster_id          = module.ecs_cluster.ecs_cluster_id 
  ecs_service_security_group_id = module.ecs_cluster.ecs_tasks_sg_id
  
  # Task definition is the only one left. We assume this name matches the resource that is missing.
  task_definition_arn = module.ecs_cluster.task_definition_arn 
}