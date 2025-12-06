# 1. Networking Module
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}

# 2. ALB Module (Requires Networking outputs)
module "alb" {
  source              = "./modules/alb"
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  # 🔑 Check modules/networking/outputs.tf for exact name
  public_subnet_ids   = module.networking.public_subnets 
}

# 3. ECS Cluster Module (Requires Networking and ALB Security Group)
module "ecs_cluster" {
  source       = "./modules/ecs"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  # 🔑 Check modules/alb/outputs.tf for exact name
  alb_sg_id    = module.alb.alb_security_group_id 
}

# 5. Route53/ACM Module (Requires ALB outputs, runs in us-east-1)
module "route53_acm" {
  source       = "./modules/route53_acm"
  domain_names = values(var.client_domains)

  providers = {
    aws = aws.us_east_1
  }

  # These outputs come from module.alb
  # 🔑 Check modules/alb/outputs.tf for exact names
  alb_dns_name = module.alb.alb_dns_name 
  alb_zone_id  = module.alb.alb_zone_id
}

# 6. Deploy Each Client Website (Scalable Loop)
module "client_deployment" {
  for_each = var.client_domains
  source   = "./modules/client_deployment"

  # Inputs derived from the for_each loop
  client_name = each.key
  domain_name = each.value
  priority    = index(keys(var.client_domains), each.key) + 1

  # 🔑 CRITICAL FIXES FOR ALL ERRORS:

  # 1. Networking Inputs
  vpc_id          = module.networking.vpc_id
  # ❌ FIX 1: Assume this is the correct output name for the list of private subnets
  private_subnets = module.networking.private_subnets 

  # 2. ALB/Listener Input
  # ❌ FIX 2: Assume this is the correct output name for the HTTPS Listener ARN
  alb_https_listener_arn = module.alb.https_listener_arn 

  # 3. ECS Inputs
  # ❌ FIX 3: Assume this is the correct output name for the ECS Cluster ARN
  ecs_cluster_id          = module.ecs_cluster.cluster_arn 

  # ❌ FIX 4: Assume the ECS Tasks SG ID is an output of the ecs_cluster module, not networking
  ecs_service_security_group_id = module.ecs_cluster.ecs_tasks_sg_id 

  # ❌ FIX 5: References the newly declared module
  task_definition_arn = module.ecs_task_definition.task_definition_arn 
}