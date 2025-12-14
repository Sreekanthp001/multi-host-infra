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
  
  # 🔑 FIX 1: ACM Certificate ARN ను జోడించండి (ALB Listener కు అవసరం)
  acm_certificate_arn = module.route53_acm.acm_certificate_arn

  # 🔑 FIX 2: ACM Validation Resource ను module output ద్వారా పాస్ చేయండి (depends_on కోసం)
  acm_validation_resource = module.route53_acm.acm_validation_resource
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "frontend-app" # మీ Docker Image పేరు
}

# 3. ECS Cluster Module (Includes Cluster, Task Definition, and SG logic)
module "ecs_cluster" {
  source       = "./modules/ecs"
  project_name = var.project_name
  aws_region = var.aws_region
  vpc_id       = module.networking.vpc_id
  alb_sg_id    = module.alb.alb_sg_id # Check outputs.tf for exact name
  ecr_repository_url = module.ecr.repository_url
}

# 4. Route53/ACM Module (Runs in us-east-1, depends on ALB outputs)
module "route53_acm" {
  source       = "./modules/route53_acm"
  
  domain_names = values(var.client_domains)

  providers = {
    aws = aws.us_east_1
  }

  # ALB info
  alb_dns_name = module.alb.alb_dns_name 
  alb_zone_id  = module.alb.alb_zone_id

  # 1. client_domains 
  client_domains = var.client_domains
  
  # 2. SES module
  verification_tokens = module.ses_configuration.verification_tokens
  dkim_tokens         = module.ses_configuration.dkim_tokens
  
  # ✅ మార్పు ఇక్కడ ఉంది: replace ఫంక్షన్ సరిగ్గా ఉపయోగించబడింది.
  ses_mx_record       = replace(module.ses_configuration.ses_mx_record, "10 ", "")
  
  mail_from_domains = module.ses_configuration.mail_from_domains 
  # 🔑 ACTION: Ensure module.route53_acm/outputs.tf contains 'acm_certificate_arn'
}

# 5. Deploy Each Client Website (Scalable Loop)
# main.tf (FINAL CORRECTIONS ON DEPENDENCIES)

# ... (rest of your root main.tf code) ...

# 5. Deploy Each Client Website (Scalable Loop)
module "client_deployment" {
  source   = "./modules/client_deployment"

  client_domains = var.client_domains
  # Inputs derived from the for_each loop (Fixes the current "Missing required argument" errors)
  # 1. Networking Inputs
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids 

  # 2. ALB/Listener Input (Uses the exact name from your modules/alb/outputs.tf)
  alb_https_listener_arn = module.alb.alb_https_listener_arn

  # 3. ECS Inputs (Uses the exact names from your modules/ecs/outputs.tf)
  ecs_cluster_id                = module.ecs_cluster.ecs_cluster_id
  ecs_service_security_group_id = module.ecs_cluster.ecs_tasks_sg_id
  task_definition_arn           = module.ecs_cluster.task_definition_arn 
}

# రూట్ main.tf లోని module "ses_configuration" బ్లాక్

module "ses_configuration" {
  source = "./modules/ses_config" 
  
 
  project_name      = var.project_name 
  
  client_domains = var.client_domains
  aws_region     = "us-east-1" 
  forwarding_email  = "sreekanthpaleti1999@gmail.com"
}


