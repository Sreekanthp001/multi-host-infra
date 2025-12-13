data "aws_region" "current" {}

# client_domains, domain_names, dkim_tokens వేరియబుల్స్ ఇప్పటికే నిర్వచించబడ్డాయి.

locals {
  
  
  all_dkim_tokens = flatten(values(var.dkim_tokens))

  
  dkim_records_data = flatten([
    for k, domain_name in var.client_domains : [
      for i in range(3) : {
        domain_name = domain_name
        token_value = element(local.all_dkim_tokens, (index(values(var.client_domains), domain_name) * 3) + i)
      }
    ]
  ])
}

# 1. Hosted Zone Creation (Multi-Zone)

resource "aws_route53_zone" "client_hosted_zones" {
  # key: client_name 
  # value: domain_name 
  for_each = var.client_domains 

  name = each.value 
  comment = "Managed by Terraform for Client: ${each.key}"
}


locals {
  zone_ids = { for k, v in aws_route53_zone.client_hosted_zones : v.name => v.zone_id }
}

# 3. ACM Certificate Creation (Single Multi-Domain SAN Certificate)
resource "aws_acm_certificate" "client_cert" {
  provider = aws
  
  
  domain_name               = var.domain_names[0] 
  validation_method         = "DNS"

  subject_alternative_names = flatten([
    for domain in var.domain_names : [domain, "*.${domain}"]
  ])

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "MultiClient-Wildcard-SAN-Cert" }
}

# 4. Create DNS Validation Records in the RESPECTIVE Hosted Zone
resource "aws_route53_record" "cert_validation_records" {
  
  for_each = {
    for dvo in aws_acm_certificate.client_cert.domain_validation_options : dvo.domain_name => dvo
  }

  allow_overwrite = true
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60

  # dvo.domain_name 
  zone_id = local.zone_ids[each.value.domain_name]
}

# 5. Wait for ACM Validation to Complete
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.client_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_records : record.fqdn]

  timeouts {
    create = "45m" 
  }
}

resource "aws_route53_record" "alb_alias" {
  for_each = var.client_domains
  
  zone_id  = local.zone_ids[each.value] 
  name     = each.value # example.com

  type = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ses_verification_txt" {
  for_each = var.client_domains

  zone_id = local.zone_ids[each.value] 
  name    = "_amazonses.${each.value}"
  type    = "TXT"
  ttl     = 600
  records = [var.verification_tokens[each.key]] 
}

resource "aws_route53_record" "client_mx_record" {
  for_each = var.client_domains
  zone_id = local.zone_ids[each.value] # ఇక్కడ మార్పు చేయాలి
  name    = each.value
  type    = "MX"
  # ...
}