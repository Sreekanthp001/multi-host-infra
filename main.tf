# root/main.tf

# 1. Networking Module (VPC, Subnets, NAT)
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

# 2. ECR Module (Container Registry)
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

# 3. SES Config Module (Email, Lambda, S3 storage)
module "ses_config" {
  source           = "./modules/ses_config"
  project_name     = var.project_name
  client_domains   = var.client_domains
  aws_region       = var.aws_region
  forwarding_email = var.forwarding_email
}

# 4. Route 53 & ACM Module (DNS, SSL, SES Records)
module "route53_acm" {
  source              = "./modules/route53_acm"
  domain_names        = values(var.client_domains) # For SSL SAN
  client_domains      = var.client_domains        # For Hosted Zones
  alb_dns_name        = module.alb.alb_dns_name
  alb_zone_id         = module.alb.alb_zone_id
  verification_tokens = module.ses_config.verification_tokens
  dkim_tokens         = module.ses_config.dkim_tokens
  ses_mx_record       = module.ses_config.ses_mx_record
  mail_from_domains   = module.ses_config.mail_from_domains
}

# 5. ALB Module (Load Balancer & Listeners)
module "alb" {
  source              = "./modules/alb"
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  acm_certificate_arn = module.route53_acm.acm_certificate_arn
  
  acm_validation_resource = module.route53_acm.acm_validation_id
}

# 6. ECS Module (Cluster & Task Definitions)
module "ecs" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  alb_sg_id          = module.alb.alb_sg_id
  aws_region         = var.aws_region
  ecr_repository_url = module.ecr.repository_url
}

# 7. Client Deployment Module (Dynamic - sree84s.site)
module "client_deployment" {
  source              = "./modules/client_deployment"
  for_each            = var.client_domains
  
  client_name                   = each.key
  client_domains                = { (each.key) = each.value }
  vpc_id                        = module.networking.vpc_id
  private_subnets               = module.networking.private_subnet_ids
  ecs_cluster_id                = module.ecs.ecs_cluster_id
  task_definition_arn           = module.ecs.task_definition_arn
  ecs_service_security_group_id = module.ecs.ecs_tasks_sg_id
  alb_https_listener_arn        = module.alb.alb_https_listener_arn
}

# 8. Static Hosting Module (Static - clavio.store)
module "static_hosting" {
  source                = "./modules/static_hosting"
  project_name          = var.project_name
  static_client_configs = var.static_client_configs
  acm_certificate_arn   = module.route53_acm.acm_certificate_arn
}