locals {
  
  dkim_records_map = merge([
    for k, tokens in var.dkim_tokens : {
      for i, token in tokens : "${k}_dkim_${i}" => { 
        token_value   = token
        client_domain = var.client_domains[k] 
      }
    }
  ]...)
}
resource "aws_route53_zone" "client_zone" {
  for_each = toset(var.domain_names) 
  name     = each.key 
}

# 2. ACM Certificate Request
# This certificate covers all domains and their wildcards (*.domain.com)
resource "aws_acm_certificate" "client_cert" {
  provider = aws

  domain_name       = var.domain_names[0] 
  validation_method = "DNS"

  subject_alternative_names = flatten([
    for domain in var.domain_names : [domain, "*.${domain}"]
  ])

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "MultiClient-Wildcard-SAN-Cert" }
}

# 3. Create DNS Validation Records in Route53
# 3. Create DNS Validation Records in Route53
resource "aws_route53_record" "cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.client_cert.domain_validation_options : dvo.domain_name => dvo
  }

  allow_overwrite = true
  # 🔑 RE-INSERTED REQUIRED ARGUMENTS
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60

  # 🔑 FINAL DEFINITIVE ZONE_ID LOOKUP FIX:
  # This uses conditional logic (substr/length) to safely strip the "*. " prefix
  # if it exists, providing the clean root domain name for the zone map lookup.
  zone_id = aws_route53_zone.client_zone[
    substr(each.value.domain_name, 0, 2) == "*." 
      ? substr(each.value.domain_name, 2, length(each.value.domain_name) - 2) 
      : each.value.domain_name
  ].zone_id
}
# 4. Wait for ACM Validation to Complete
# This is a critical blocker. Terraform will pause here until the certificate status is 'ISSUED'.
resource "aws_acm_certificate_validation" "cert_validation" {
  # REMOVE 'provider = aws.us_east_1' HERE for the same reason
  certificate_arn         = aws_acm_certificate.client_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_records : record.fqdn]

  timeouts {
    create = "45m" 
  }
}

# 5. Route 53 A Records to ALB
# Maps each domain to the ALB DNS name using an Alias record.
resource "aws_route53_record" "alb_alias" {
  for_each = toset(var.domain_names)
  zone_id  = aws_route53_zone.client_zone[each.key].zone_id
  name     = each.key # example.com

  type = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# 6. SES Verification TXT Record
resource "aws_route53_record" "ses_verification_txt" {
  for_each = var.client_domains
  
  zone_id = aws_route53_zone.client_zone[each.value].zone_id 
  name    = "_amazonses.${each.value}"
  type    = "TXT"
  ttl     = 600
  
  records = [var.verification_tokens[each.key]] 
}


# 7. SES DKIM CNAME Records (FINAL FIX - using for_each on locals map)
resource "aws_route53_record" "ses_dkim_records" {
  
  
  for_each = local.dkim_records_map 

  
  zone_id = aws_route53_zone.client_zone[each.value.client_domain].zone_id 
  
  # each.value.token_value 
  name    = "${each.value.token_value}._domainkey"
  
  type    = "CNAME"
  ttl     = 600
  
  # each.value.token_value 
  records = ["${each.value.token_value}.dkim.amazonses.com"] 
}

# 8. SES MX Record (Incoming Mail)
resource "aws_route53_record" "client_mx_record" {
  for_each = var.client_domains
  
  zone_id = aws_route53_zone.client_zone[each.value].zone_id 
  name    = each.value
  type    = "MX"
  ttl     = 300
  
  records = [var.ses_mx_record] 
}