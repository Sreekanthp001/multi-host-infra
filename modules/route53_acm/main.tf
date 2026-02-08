data "aws_region" "current" {}

locals {
  # UNIFIED DOMAIN MAP: Merges Dynamic (ECS) and Static (CloudFront) domains
  all_domains = merge(
    # Dynamic domains (ECS + ALB)
    {
      for k, v in var.client_domains : k => {
        domain = v.domain
        type   = "dynamic"  # Routes to ALB
        priority = lookup(v, "priority", null)
        parent_zone_name = lookup(v, "parent_zone_name", null) # Support sub-domains
      }
    },
    # Static domains (S3 + CloudFront)
    {
      for k, v in var.static_client_configs : k => {
        domain = v.domain_name
        type   = "static"  # Routes to CloudFront
        priority = null
        parent_zone_name = lookup(v, "parent_zone_name", null) # Support sub-domains
      }
    }
  )

  # Filter: Only create zones for domains that DON'T have a parent_zone_name defined
  domains_needing_zones = merge(
    {
      for k, v in local.all_domains : k => v
      if v.parent_zone_name == null
    },
    # Ensure the main domain gets a zone even if not in the client lists
    var.main_domain != "" ? {
      "infrastructure_main" = {
        domain = var.main_domain
        type   = "system"
      }
    } : {}
  )

  # Extract just the domain names for ACM certificate SANs
  all_domain_names = distinct(concat(
    [for k, v in local.all_domains : v.domain],
    var.main_domain != "" ? [var.main_domain] : []
  ))

  # Map of ONLY the zones we created
  created_zone_ids = { for k, v in aws_route53_zone.client_hosted_zones : v.name => v.zone_id }

  # Mapping domain names to their respective Route 53 Hosted Zone IDs
  # Logic: If parent_zone_name exists, use that zone's ID. Otherwise, use the domain's own zone ID.
  zone_ids = merge(
    {
      for k, v in local.all_domains : v.domain => (
        v.parent_zone_name != null ? 
        local.created_zone_ids[v.parent_zone_name] : 
        local.created_zone_ids[v.domain]
      )
    },
    # Ensure main_domain is present in zone_ids map
    var.main_domain != "" ? { (var.main_domain) = local.created_zone_ids[var.main_domain] } : {}
  )

  # SCALING FIX: Creating a flat list of domain index and token index (0, 1, 2)
  # Only for dynamic domains that need SES configuration
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
# Creates Route53 hosted zones for ALL domains (dynamic + static)
resource "aws_route53_zone" "client_hosted_zones" {
  for_each = local.domains_needing_zones

  name    = each.value.domain
  comment = "Managed by Terraform for Client: ${each.key} (${each.value.type})"
}

# 2. Multi-Domain SAN Certificate with Wildcards
# Includes ALL domains (100+) in a single certificate
resource "aws_acm_certificate" "client_cert" {
  domain_name               = local.all_domain_names[0]
  validation_method         = "DNS"
  subject_alternative_names = flatten([
    for domain in local.all_domain_names : [domain, "*.${domain}"]
  ])

  lifecycle {
    create_before_destroy = true
  }

  tags = { 
    Name = "MultiClient-Wildcard-SAN-Cert"
    TotalDomains = length(local.all_domain_names)
  }
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

# 5a. Route 53 A Records - DYNAMIC DOMAINS (Alias to ALB)
# Automatically created for all domains with type = "dynamic"
resource "aws_route53_record" "alb_alias" {
  for_each = {
    for k, v in local.all_domains : k => v if v.type == "dynamic"
  }
  
  zone_id  = local.zone_ids[each.value.domain]
  name     = each.value.domain
  type     = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# 5b. Route 53 A Records - STATIC DOMAINS (Alias to CloudFront)
# Automatically created for all domains with type = "static"
resource "aws_route53_record" "cloudfront_alias" {
  for_each = {
    for k, v in local.all_domains : k => v if v.type == "static"
  }
  
  zone_id  = local.zone_ids[each.value.domain]
  name     = each.value.domain
  type     = "A"

  alias {
    name                   = var.cloudfront_domain_names[each.key]
    zone_id                = var.cloudfront_hosted_zone_ids[each.key]
    evaluate_target_health = false
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
/* resource "aws_route53_record" "ses_dkim_records" {
  for_each = local.dkim_records_map
  
  zone_id = local.zone_ids[each.value.domain_name]
  name    = "${each.value.token_value}._domainkey.${each.value.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${each.value.token_value}.dkim.amazonses.com"]
} */

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