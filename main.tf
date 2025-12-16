# main.tf (FINAL REFACTORING FOR SCALABILITY)

# 1. Networking Module (No Change)
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}

# 2. ALB Module (No Change)
module "alb" {
  source              = "./modules/alb"
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids

  // FIX: acm_certificate_arn output is now a map. Extract the ARN for the dynamic client ('sree84s-prod' or similar default key).
  // Assuming 'sree84s-prod' is the key for the main certificate used by the ALB listener.
  acm_certificate_arn = module.route53_acm.acm_certificate_arn["sree84s-prod"]
  
  // FIX: acm_validation_resource is now a map. Extract the specific resource for the dynamic client.
  acm_validation_resource = module.route53_acm.acm_validation_resource["sree84s-prod"]
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "frontend-app" 
}

# 3. ECS Cluster Module (No Change)
module "ecs_cluster" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  aws_region         = var.aws_region
  vpc_id             = module.networking.vpc_id
  alb_sg_id          = module.alb.alb_sg_id
  ecr_repository_url = module.ecr.repository_url
}

# 4. SES Configuration Module (Using the new client_configs map)
module "ses_configuration" {
  source             = "./modules/ses_config" 
  project_name       = var.project_name 
  
  // 🔑 CHANGE 1: Using client_configs map and extracting domain names
  client_domains     = { for k, v in var.client_configs : k => v.domain_name }
  
  aws_region         = "us-east-1" 
  forwarding_email   = "sreekanthpaleti1999@gmail.com"
}


# 5. Route53/ACM Module (Using the new client_configs map)
module "route53_acm" {
  source      = "./modules/route53_acm"
  
  providers = {
    aws = aws.us_east_1
  }

  // 1. 🔑 FIX: పాత 'domain_names' మరియు 'client_domains' తొలగించండి.
  // వీటి స్థానంలో కొత్త unified client_configs map ని పంపండి.
  client_configs_map = var.client_configs

  # ALB info
  alb_dns_name = module.alb.alb_dns_name 
  alb_zone_id  = module.alb.alb_zone_id

  # 2. SES module inputs
  verification_tokens = module.ses_configuration.verification_tokens
  dkim_tokens         = module.ses_configuration.dkim_tokens
  
  # ✅ మార్పు ఇక్కడ ఉంది: replace ఫంక్షన్ సరిగ్గా ఉపయోగించబడింది.
  ses_mx_record       = replace(module.ses_configuration.ses_mx_record, "10 ", "")
  
  mail_from_domains   = module.ses_configuration.mail_from_domains 
}


# 6. Dynamic Client Deployment (Client 1 - ECS Service, Target Group, ALB Rule)
module "client_deployment" {
  source  = "./modules/client_deployment"

  // Loop only through Dynamic clients
  for_each = { for k, v in var.client_configs : k => v if v.hosting_type == "dynamic" }

  // 🔑 Inputs expected by the Module:
  client_id              = each.key
  domain_name            = each.value.domain_name
  docker_image_tag       = each.value.docker_image_tag 
  listener_priority      = index(keys(var.client_configs), each.key) + 10

  // Other infrastructure inputs (No change)
  vpc_id                 = module.networking.vpc_id
  private_subnets        = module.networking.private_subnet_ids
  alb_https_listener_arn = module.alb.alb_https_listener_arn
  ecs_cluster_id         = module.ecs_cluster.ecs_cluster_id
  ecs_service_security_group_id = module.ecs_cluster.ecs_tasks_sg_id
  task_definition_arn    = module.ecs_cluster.task_definition_arn 
}


// 7. Static Client Deployment (Client 2 - S3, CloudFront)
module "static_client_site" {
  source = "./modules/static-hosting"

  for_each = { for k, v in var.client_configs : k => v if v.hosting_type == "static" }

  client_id   = each.key 
  domain_name = each.value.domain_name
  s3_prefix   = var.s3_bucket_prefix 
  s3_suffix   = each.value.s3_bucket_suffix 
}