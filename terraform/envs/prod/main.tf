# ... (Previous terraform and provider blocks) ...

# 01. Networking Module Call
module "networking" {
  source = "../../modules/01_networking"
  
  project_name       = "ClientHostingProd"
  aws_region         = "us-east-1"
}

# 02. Core Services Module Call
module "core_services" {
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
  source      = "../../modules/03_client_onboarding"
  zone_id     = var.hosted_zone_id
  domain_name = var.venturemond_domain
  vpc_id      = module.networking.vpc_id
  project_name = var.project_name
  environment  = var.environment
  client_name  = "venturemond"
  alb_zone_id  = module.alb.alb_zone_id
  alb_dns_name = module.alb.alb_dns_name
}


# 3B. Onboard Dynamic Site Client: sampleclient.com (Dynamic Fargate/ALB)
module "client_sampleclient" {
  source      = "../../modules/03_client_onboarding"
  zone_id     = var.hosted_zone_id
  domain_name = var.sampleclient_domain
  vpc_id      = module.networking.vpc_id
  project_name = var.project_name
  environment  = var.environment
  client_name  = "sampleclient"
  alb_zone_id  = module.alb.alb_zone_id
  alb_dns_name = module.alb.alb_dns_name
  site_type = var.sampleclient_site_type
  certificate_arn = var.sampleclient_certificate_arn
}


output "acm_validation_records" {
  value = module.core_services.acm_validation_records
}

# Output ECR URL for CI/CD
 output "sampleclient_ecr_url" {
  value = module.client_sampleclient.ecr_repository_url
} 