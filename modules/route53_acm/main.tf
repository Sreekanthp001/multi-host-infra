data "aws_region" "current" {}

locals {
  # Mapping domain names to their respective Route 53 Hosted Zone IDs
  zone_ids = { for k, v in aws_route53_zone.client_hosted_zones : v.name => v.zone_id }

  # SCALING FIX: Creating a flat list of domain index and token index (0, 1, 2)
  # Idi static ga untundi kabatti Terraform plan lo error ivvadu
  dkim_flat = flatten([
    for client_key, domain_val in var.client_domains : [
      for i in range(3) : {
        key         = "${client_key}_${i}"
        client_key  = client_key
        token_index = i
        domain_name = domain_val.domain
      }
    ]
  ])

  dkim_map = { for item in local.dkim_flat : item.key => item }
}

# 1. Multi-Domain Hosted Zone Creation
resource "aws_route53_zone" "client_hosted_zones" {
  for_each = var.client_domains 

  name    = each.value.domain
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
  
  zone_id  = local.zone_ids[each.value.domain] 
  name     = each.value.domain
  type     = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# 6. SES Verification & Security Records
resource "aws_route53_record" "ses_dkim_records" {
  for_each = local.dkim_map
  
  zone_id = local.zone_ids[each.value.domain_name]
  
  # Token value ni records lona (value side) vaadutunnam, name side kadhu
  # Dheenivalla Terraform ki keys mundhe telisipothayi
  name    = "${var.dkim_tokens[each.value.client_key][each.value.token_index]}._domainkey.${each.value.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${var.dkim_tokens[each.value.client_key][each.value.token_index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "client_mx_record" {
  for_each = var.client_domains
  zone_id  = local.zone_ids[each.value.domain] 
  name     = each.value.domain
  type     = "MX"
  ttl      = 300
  records  = ["10 ${var.ses_mx_record}"]
}

# SCALING FIX: Using for_each for DKIM instead of count
resource "aws_route53_record" "ses_dkim_records" {
  for_each = local.dkim_records_map
  
  zone_id = local.zone_ids[each.value.domain_name]
  name    = "${each.value.token_value}._domainkey.${each.value.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${each.value.token_value}.dkim.amazonses.com"]
}

resource "aws_route53_record" "client_spf_record" {
  for_each = var.client_domains
  zone_id  = local.zone_ids[each.value.domain] 
  name     = each.value.domain
  type     = "TXT"
  ttl      = 600
  records  = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "client_dmarc_record" {
  for_each = var.client_domains
  zone_id  = local.zone_ids[each.value.domain] 
  name     = "_dmarc.${each.value.domain}"
  type     = "TXT"
  ttl      = 600
  records  = ["v=DMARC1; p=none; rua=mailto:dmarc-reports@${each.value.domain}"]
}