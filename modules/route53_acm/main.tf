# modules/route53_acm/main.tf

data "aws_region" "current" {}

locals {
  # Flattening DKIM tokens for count-based resource creation
  all_dkim_tokens = flatten(values(var.dkim_tokens))

  dkim_records_data = flatten([
    for k, domain_name in var.client_domains : [
      for i in range(3) : {
        domain_name = domain_name
        token_value = element(var.dkim_tokens[k], i)
      }
    ]
  ])
  
  # Mapping domain names to their respective Route 53 Hosted Zone IDs
  zone_ids = { for k, v in aws_route53_zone.client_hosted_zones : v.name => v.zone_id }
}

# 1. Multi-Domain Hosted Zone Creation
resource "aws_route53_zone" "client_hosted_zones" {
  for_each = var.client_domains 

  name    = each.value 
  comment = "Managed by Terraform for Client: ${each.key}"
}

# 2. Multi-Domain SAN Certificate with Wildcards
resource "aws_acm_certificate" "client_cert" {
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

# 3. DNS Validation Records
resource "aws_route53_record" "cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.client_cert.domain_validation_options : dvo.domain_name => dvo
  }
  
  allow_overwrite = true
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60

  # Logic to map wildcard domains back to the root hosted zone ID
  zone_id = local.zone_ids[replace(each.value.domain_name, "*.", "")]
}

# 4. ACM Validation Waiter
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.client_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_records : record.fqdn]
}

# 5. Route 53 A Records (Alias to ALB)
resource "aws_route53_record" "alb_alias" {
  for_each = var.client_domains
  
  zone_id  = local.zone_ids[each.value] 
  name     = each.value 
  type     = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# 6. SES Verification & Security Records (SPF, DMARC, MX)
resource "aws_route53_record" "ses_verification_txt" {
  for_each = var.client_domains
  zone_id  = local.zone_ids[each.value] 
  name     = "_amazonses.${each.value}"
  type     = "TXT"
  ttl      = 600
  records  = [var.verification_tokens[each.key]] 
}

resource "aws_route53_record" "client_mx_record" {
  for_each = var.client_domains
  zone_id  = local.zone_ids[each.value] 
  name     = each.value
  type     = "MX"
  ttl      = 300
  records  = ["10 ${var.ses_mx_record}"]
}

resource "aws_route53_record" "ses_dkim_records" {
  count   = length(local.dkim_records_data)
  zone_id = local.zone_ids[local.dkim_records_data[count.index].domain_name]
  name    = "${local.dkim_records_data[count.index].token_value}._domainkey"
  type    = "CNAME"
  ttl     = 600
  records = ["${local.dkim_records_data[count.index].token_value}.dkim.amazonses.com"]
}

resource "aws_route53_record" "client_spf_record" {
  for_each = var.client_domains
  zone_id  = local.zone_ids[each.value] 
  name     = each.value
  type     = "TXT"
  ttl      = 600
  records  = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "client_dmarc_record" {
  for_each = var.client_domains
  zone_id  = local.zone_ids[each.value] 
  name     = "_dmarc.${each.value}"
  type     = "TXT"
  ttl      = 600
  records  = ["v=DMARC1; p=none; rua=mailto:dmarc-reports@${each.value}"]
}