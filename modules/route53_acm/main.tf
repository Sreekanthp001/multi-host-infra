data "aws_region" "current" {}

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

# 1. Hosted Zone Creation - రూట్ డొమైన్ కోసం మాత్రమే ఒకే Hosted Zone సృష్టించండి
resource "aws_route53_zone" "client_zone" {
  # var.domain_names లోని మొదటి ఎలిమెంట్ రూట్ డొమైన్ అని ఊహిస్తున్నాము (ఉదా. sree84s.site)
  count    = length(var.domain_names) > 0 ? 1 : 0
  name     = var.domain_names[0]
}

# వేరియబుల్స్ నుండి రూట్ జోన్ ID ని తీసుకోవడానికి local వేరియబుల్
locals {
  root_zone_id = try(aws_route53_zone.client_zone[0].zone_id, "")
}


resource "aws_acm_certificate" "client_cert" {
  provider = aws

  domain_name             = var.domain_names[0] 
  validation_method       = "DNS"

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

  # సరిచేయబడింది: రూట్ Hosted Zone ID ని ఉపయోగించండి
  zone_id = local.root_zone_id
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
  # సరిచేయబడింది: రూట్ Hosted Zone ID ని ఉపయోగించండి
  zone_id  = local.root_zone_id
  name     = each.key # example.com

  type = "A"

  alias {
    name             = var.alb_dns_name
    zone_id          = var.alb_zone_id
    evaluate_target_health = true
  }
}

# 6. SES Verification TXT Record
resource "aws_route53_record" "ses_verification_txt" {
  for_each = var.client_domains

  # సరిచేయబడింది: రూట్ Hosted Zone ID ని ఉపయోగించండి
  zone_id = local.root_zone_id
  name    = "_amazonses.${each.value}"
  type    = "TXT"
  ttl     = 600

  # verification_tokens 
  records = [var.verification_tokens[each.key]] 
}

# 7. SES DKIM CNAME Records 
resource "aws_route53_record" "ses_dkim_records" {

  # count 
  count = length(local.dkim_records_data)

  # సరిచేయబడింది: రూట్ Hosted Zone ID ని ఉపయోగించండి
  zone_id = local.root_zone_id

  name    = "${local.dkim_records_data[count.index].token_value}._domainkey"

  type    = "CNAME"
  ttl     = 600

  records = ["${local.dkim_records_data[count.index].token_value}.dkim.amazonses.com"]
}

# 8. SES MX Record (Incoming Mail)
resource "aws_route53_record" "client_mx_record" {
  for_each = var.client_domains

  # సరిచేయబడింది: రూట్ Hosted Zone ID ని ఉపయోగించండి
  zone_id = local.root_zone_id 
  name    = each.value
  type    = "MX"
  ttl     = 300

  # ses_mx_record 
  records = [var.ses_mx_record] 
}

# 9. SPF Record (TXT) - Root Domain కోసం
resource "aws_route53_record" "client_spf_record" {
  for_each = var.client_domains

  # సరిచేయబడింది: రూట్ Hosted Zone ID ని ఉపయోగించండి
  zone_id = local.root_zone_id
  name    = each.key
  type    = "TXT"
  ttl     = 600
  records = [
    "v=spf1 include:amazonses.com ~all",
  ]
}

# 10. DMARC Record (TXT)
resource "aws_route53_record" "client_dmarc_record" {
  for_each = var.client_domains

  # సరిచేయబడింది: రూట్ Hosted Zone ID ని ఉపయోగించండి
  zone_id = local.root_zone_id
  name    = "_dmarc.${each.key}"
  type    = "TXT"
  ttl     = 600
  records = [
    "v=DMARC1; p=none; rua=mailto:dmarc-reports@${each.key}; pct=100; adkim=r; aspf=r",
  ]
}


# 11. Custom MAIL FROM for MX Record 
resource "aws_route53_record" "client_mail_from_mx" {
  for_each = var.client_domains

  # సరిచేయబడింది: రూట్ Hosted Zone ID ని ఉపయోగించండి
  zone_id = local.root_zone_id
  name    = var.mail_from_domains[each.key]
  type    = "MX"
  ttl     = 600
  records = [
    
    "10 feedback-smtp.${data.aws_region.current.name}.amazonaws.com", 
  ]
}

# 12. Custom MAIL FROM for SPF TXT Record
resource "aws_route53_record" "client_mail_from_txt" {
  for_each = var.client_domains

  # సరిచేయబడింది: రూట్ Hosted Zone ID ని ఉపయోగించండి
  zone_id = local.root_zone_id
  name    = var.mail_from_domains[each.key]
  type    = "TXT"
  ttl     = 600
  records = [
    "v=spf1 include:amazonses.com ~all",
  ]
}