locals {
  # 1. అన్ని DKIM టోకెన్లను ఒకే ఫ్లాట్ లిస్ట్‌గా చేస్తుంది.
  all_dkim_tokens = flatten(values(var.dkim_tokens))
  
  # 2. DKIM రికార్డు డేటా లిస్ట్‌ను సృష్టిస్తుంది
  dkim_records_data = flatten([
    for k, domain_name in var.client_domains : [
      for i in range(3) : { # ప్రతి డొమైన్‌కు 3 రికార్డులు
        domain_name = domain_name
        # టోకెన్ విలువను ఇక్కడ unknown గా ఉంచుతాము (apply-time లో వస్తుంది)
        # element(list, index) ఉపయోగించి, ఫ్లాట్ టోకెన్ లిస్ట్ నుండి టోకెన్ విలువను పొందుతాము
        token_value = element(local.all_dkim_tokens, (index(values(var.client_domains), domain_name) * 3) + i)
      }
    ]
  ])
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

# 7. SES DKIM CNAME Records (FINAL ATTEMPT: Using stable locals and count.index)
resource "aws_route53_record" "ses_dkim_records" {
  
  count = length(local.dkim_records_data)

  # count.index ద్వారా లెక్కించిన డొమైన్ మరియు టోకెన్ విలువను ఉపయోగిస్తాము
  current_record = local.dkim_records_data[count.index]

  zone_id = aws_route53_zone.client_zone[current_record.domain_name].zone_id
  
  name    = "${current_record.token_value}._domainkey"
  type    = "CNAME"
  ttl     = 600
  
  records = ["${current_record.token_value}.dkim.amazonses.com"]
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