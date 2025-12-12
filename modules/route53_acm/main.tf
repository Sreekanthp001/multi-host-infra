locals {
  # (పాత all_dkim_tokens ని తొలగించండి లేదా దీనికి మార్చండి)
  # DKIM CNAME రికార్డులను సృష్టించడానికి అవసరమైన మొత్తం డేటాను కలిగి ఉన్న మ్యాప్‌ను సిద్ధం చేస్తుంది.
  dkim_records_map = merge([
    for k, tokens in var.dkim_tokens : {
      for i, token in tokens : "${k}_dkim_${i}" => { # కీ: domainkey_dkim_0
        domain_name = var.client_domains[k] # ఏ డొమైన్‌కు చెందింది
        token_value = token                # అసలు టోకెన్ విలువ (apply-time లో వస్తుంది)
      }
    }
  ]...)
}

# 1. ప్రతి డొమైన్ కోసం Route 53 Hosted Zone ను సృష్టిస్తుంది
resource "aws_route53_zone" "client_zone" {
  for_each = toset(var.domain_names)
  name     = each.key
}

# 2. ACM Certificate Request
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

# 3. Create DNS Validation Records in Route53
resource "aws_route53_record" "cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.client_cert.domain_validation_options : dvo.domain_name => dvo
  }

  allow_overwrite = true
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60

  # Zone ID కోసం రూట్ డొమైన్ పేరును లెక్కించే లాజిక్
  zone_id = aws_route53_zone.client_zone[
    substr(each.value.domain_name, 0, 2) == "*." 
      ? substr(each.value.domain_name, 2, length(each.value.domain_name) - 2) 
      : each.value.domain_name
  ].zone_id
}

# 4. Wait for ACM Validation to Complete
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.client_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_records : record.fqdn]

  timeouts {
    create = "45m" 
  }
}

# 5. Route 53 A Records to ALB
resource "aws_route53_record" "alb_alias" {
  for_each = toset(var.domain_names)
  zone_id  = aws_route53_zone.client_zone[each.key].zone_id
  name     = each.key # example.com

  type = "A"

  alias {
    name                 = var.alb_dns_name
    zone_id              = var.alb_zone_id
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
  
  # verification_tokens మాడ్యూల్ అవుట్‌పుట్ నుండి వస్తుంది
  records = [var.verification_tokens[each.key]] 
}

# 7. SES DKIM CNAME Records (The Final Stable Fix)
# 7. SES DKIM CNAME Records (The Final Stable Fix using for_each)
resource "aws_route53_record" "ses_dkim_records" {
  
  # local.dkim_records_map పై లూప్ చేస్తున్నాము. కీలు ప్లాన్-టైమ్‌లో స్థిరంగా ఉంటాయి.
  for_each = local.dkim_records_map

  # zone_id కోసం each.value.domain_name ను వాడుతున్నాము
  zone_id = aws_route53_zone.client_zone[each.value.domain_name].zone_id 
  
  # పేరు కోసం each.value.token_value ను వాడుతున్నాము
  name    = "${each.value.token_value}._domainkey"
  
  type    = "CNAME"
  ttl     = 600
  
  # records కోసం each.value.token_value ను వాడుతున్నాము
  records = ["${each.value.token_value}.dkim.amazonses.com"]
}

# 8. SES MX Record (Incoming Mail)
resource "aws_route53_record" "client_mx_record" {
  for_each = var.client_domains
  
  zone_id = aws_route53_zone.client_zone[each.value].zone_id 
  name    = each.value
  type    = "MX"
  ttl     = 300
  
  # ses_mx_record మాడ్యూల్ అవుట్‌పుట్ నుండి వస్తుంది
  records = [var.ses_mx_record] 
}