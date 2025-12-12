locals {
  # 1. అన్ని DKIM టోకెన్లను ఒకే ఫ్లాట్ లిస్ట్‌గా చేస్తుంది.
  all_dkim_tokens = flatten(values(var.dkim_tokens))
  
  # 2. DKIM రికార్డుల డేటా లిస్ట్‌ను సృష్టిస్తుంది
  dkim_records_data = flatten([
    for k, domain_name in var.client_domains : [
      for i in range(3) : {
        domain_name = domain_name
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

# 7. SES DKIM CNAME Records (THE FINAL GUARANTEED SYNTAX FIX)
resource "aws_route53_record" "ses_dkim_records" {
  
  # count ఇప్పుడు స్థిరంగా లెక్కించబడుతుంది
  count = length(local.dkim_records_data)

  # ప్రతి ఆట్రిబ్యూట్‌లోనూ పూర్తి లెక్కింపును ఉపయోగిస్తున్నాము
  
  # డొమైన్ పేరును లెక్కించే లాజిక్‌ను నేరుగా zone_id లో ఉపయోగిస్తున్నాము
  zone_id = aws_route53_zone.client_zone[
    local.dkim_records_data[count.index].domain_name
  ].zone_id
  
  # టోకెన్ విలువను లెక్కించే లాజిక్‌ను name లో ఉపయోగిస్తున్నాము
  name    = "${local.dkim_records_data[count.index].token_value}._domainkey"
  
  type    = "CNAME"
  ttl     = 600
  
  # టోకెన్ విలువను లెక్కించే లాజిక్‌ను records లో ఉపయోగిస్తున్నాము
  records = ["${local.dkim_records_data[count.index].token_value}.dkim.amazonses.com"]
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

# 1. SPF Record (TXT) - Root Domain కోసం
# v=spf1 include:amazonses.com ~all
resource "aws_route53_record" "client_spf_record" {
  for_each = var.client_domains

  zone_id = aws_route53_zone.client_zone[each.key].zone_id
  name    = each.key
  type    = "TXT"
  ttl     = 600
  records = [
    "v=spf1 include:amazonses.com ~all",
  ]
  comment = "SPF record for AWS SES"
}

# 2. DMARC Record (TXT)
# p=none అనేది మానిటరింగ్ మోడ్, deliverability ను పరీక్షించడానికి ఉత్తమం.
resource "aws_route53_record" "client_dmarc_record" {
  for_each = var.client_domains

  zone_id = aws_route53_zone.client_zone[each.key].zone_id
  name    = "_dmarc.${each.key}"
  type    = "TXT"
  ttl     = 600
  records = [
    # rua=mailto:dmarc-reports@${each.key} రిపోర్ట్‌లను స్వీకరించే చిరునామా.
    "v=DMARC1; p=none; rua=mailto:dmarc-reports@${each.key}; pct=100; adkim=r; aspf=r",
  ]
  comment = "DMARC record"
}


# 3. Custom MAIL FROM కోసం MX రికార్డు (ses_configuration మాడ్యూల్ నుండి విలువను తీసుకుంటుంది)
resource "aws_route53_record" "client_mail_from_mx" {
  for_each = var.client_domains

  zone_id = aws_route53_zone.client_zone[each.key].zone_id
  # ఇక్కడ మనం mail_from_domains వేరియబుల్ నుండి 'mail.sree84s.site' తీసుకుంటాము
  name    = var.mail_from_domains[each.key]
  type    = "MX"
  ttl     = 600
  records = [
    "10 feedback-smtp.${var.aws_region}.amazonaws.com",
  ]
  comment = "MX record for Custom MAIL FROM domain verification"
}

# 4. Custom MAIL FROM కోసం SPF TXT రికార్డు
resource "aws_route53_record" "client_mail_from_txt" {
  for_each = var.client_domains

  zone_id = aws_route53_zone.client_zone[each.key].zone_id
  name    = var.mail_from_domains[each.key]
  type    = "TXT"
  ttl     = 600
  records = [
    "v=spf1 include:amazonses.com ~all",
  ]
  comment = "SPF record for Custom MAIL FROM domain"
}