# ... (Previous terraform and provider blocks) ...

# 01. Networking Module Call
module "networking" {
  source = "../../modules/01_networking"
  
  project_name       = "ClientHostingProd"
  aws_region         = "us-east-1"
}

# 02. Core Services Module Call
/* module "core_services" {
  source = "../../modules/02_core_services"
  
  project_name        = "ClientHostingProd"
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  
  # IMPORTANT: The primary domain must be the one that hosts the Route53 zone.
  base_domain         = "venturemond.com" # Placeholder
  client_domains      = ["sampleclient.com"] # Placeholder
}

# --- 03. Client Onboarding Calls ---

# 3A. Onboard Static Site Client: venturemond.com (Static S3/CloudFront)
module "client_venturemond" {
  source           = "../../modules/03_client_onboarding"
  project_name     = "ClientHostingProd"
  domain_name      = "venturemond.com"
  site_type        = "static"
  certificate_arn  = module.core_services.acm_certificate_arn
} 

# 3B. Onboard Dynamic Site Client: sampleclient.com (Dynamic Fargate/ALB)
module "client_sampleclient" {
  source           = "../../modules/03_client_onboarding"
  project_name     = "ClientHostingProd"
  domain_name      = "sampleclient.com"
  site_type        = "fargate" 
  certificate_arn  = module.core_services.acm_certificate_arn
  
  # Fargate Specific Inputs:
  alb_dns_name     = module.core_services.alb_dns_name
  alb_listener_arn = module.core_services.https_listener_arn
  ecs_cluster_id   = module.core_services.ecs_cluster_id
  ecs_tasks_sg_id  = module.core_services.ecs_tasks_sg_id
  private_subnet_ids = module.networking.private_subnet_ids
  vpc_id           = module.networking.vpc_id # Needed for Target Group
}*/


output "acm_validation_records" {
  value = module.core_services.acm_validation_records
}

# Output ECR URL for CI/CD
output "sampleclient_ecr_url" {
  value = module.client_sampleclient.ecr_repository_url
}