data "aws_region" "current" {}

locals {
  // 1. All active domains (used for R53 Zone creation and ACM)
  // We use the new client_configs_map passed from the root module.
  active_domains = { 
    for k, v in var.client_configs_map : k => v.domain_name 
  }
  
  // 2. SES DKIM Token Logic (Refactored for the new structure)
  // Flatten the DKIM tokens received from the SES module for all clients.
  // We rely on the SES module to pass the dkim_tokens as a map indexed by client_id.
  
  dkim_records_data = flatten([
    for client_id, domain_name in local.active_domains : [
      for i in range(3) : {
        // We use the client_id to access the correct set of DKIM tokens from the var.dkim_tokens map
        domain_name = domain_name
        token_name  = element(var.dkim_tokens[client_id], i)
        token_value = element(var.dkim_tokens[client_id], i)
      }
    ]
  ])
  
  // 3. Zone IDs Map (Must be defined AFTER the resource)
  // NOTE: This must reference the resource created later in this file.
  zone_ids = { for k, v in aws_route53_zone.client_hosted_zones : v.name => v.zone_id }
}

# 1. Hosted Zone Creation (Multi-Zone)
# Creates a Hosted Zone for every domain in var.client_domains
resource "aws_route53_zone" "client_hosted_zones" {
  for_each = local.active_domains 

  name    = each.value 
  comment = "Managed by Terraform for Client: ${each.key}"
}


# 3. ACM Certificate Creation (Single Multi-Domain SAN Certificate)
resource "aws_acm_certificate" "client_cert" {
  // ✅ NEW LOGIC: Use the map for for_each
  for_each = local.active_domains 
  
  domain_name       = each.value
  validation_method = "DNS"
  
  // Subject Alternative Names (SANs) - for www version
  subject_alternative_names = ["*.${each.value}", "www.${each.value}"]
  
  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "MultiClient-Wildcard-SAN-Cert" }
}

# 4. Create DNS Validation Records in the RESPECTIVE Hosted Zone
resource "aws_route53_record" "cert_validation_records" {
  // 1. FIX: Combine the outer loop (client_configs) and inner loop (dvo) 
  // into a single flattened map structure for for_each.

  for_each = {
    // We loop over all ACM certificates created in the module (one per client).
    for dvo in flatten([
      for client_id, cert in aws_acm_certificate.client_cert : [
        for dvo in cert.domain_validation_options : {
          # Create a unique key (client_id + dvo_domain_name)
          key                 = "${client_id}-${dvo.domain_name}" 
          client_id           = client_id
          domain_name         = dvo.domain_name
          resource_record_name  = dvo.resource_record_name
          resource_record_type  = dvo.resource_record_type
          resource_record_value = dvo.resource_record_value
        }
      ]
    ]) : dvo.key => dvo # Map by the unique key
  }
  
  allow_overwrite = true
  
  # Access data from the flattened map using each.value
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60

  # 2. Zone ID Fix: Use the client_id to find the correct Hosted Zone.
  # We assume the Hosted Zone names match the certificate domain name.
  # The key for aws_route53_zone.client_hosted_zones is the client_id.
  zone_id = aws_route53_zone.client_hosted_zones[each.value.client_id].zone_id
}

# 5. Wait for ACM Validation to Complete
resource "aws_acm_certificate_validation" "cert_validation" {
  // We loop over all domains (dynamic and static) that need certificates.
  for_each = local.active_domains 

  // Access the specific certificate instance using [each.key] (client_id)
  certificate_arn         = aws_acm_certificate.client_cert[each.key].arn
  
  // FIX: Iterate over ALL validation records and filter only those that belong to the current client (each.key).
  validation_record_fqdns = [
    // aws_route53_record.cert_validation_records లో ఉన్న కీ (key) client_id తో మొదలవుతుందో లేదో తనిఖీ చేయండి.
    for record_key, record in aws_route53_record.cert_validation_records : record.fqdn
    if startswith(record_key, "${each.key}-") 
  ]

  timeouts {
    create = "45m" 
  }
}

# 6. Route 53 A Records (Alias to ALB)
resource "aws_route53_record" "alb_alias" {
  // Filter the client_configs_map to include ONLY clients with hosting_type = "dynamic".
  // Static clients (calvio.store) will be ignored here and handled by the CloudFront records.
  for_each = {
    for client_id, config in var.client_configs_map : client_id => config.domain_name
    if config.hosting_type == "dynamic"
  }
  
  // Zone ID reference using the domain name (each.value is the domain name)
  // This relies on the 'local.zone_ids' block being correctly defined to map domain_name -> zone_id.
  zone_id  = local.zone_ids[each.value] 
  name     = each.value 

  type = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# 7. SES Verification TXT Record
resource "aws_route53_record" "ses_verification_txt" {
  for_each = local.active_domains

  # Zone ID reference using the domain name (each.value)
  zone_id = local.zone_ids[each.value] 
  name    = "_amazonses.${each.value}"
  type    = "TXT"
  ttl     = 600
  records = [var.verification_tokens[each.key]] 
}

# 8. SES MX Record (Incoming Mail)
resource "aws_route53_record" "client_mx_record" {
  for_each = local.active_domains

  # Zone ID reference using the domain name (each.value)
  zone_id = local.zone_ids[each.value] 
  name    = each.value
  type    = "MX"
  ttl     = 300

  # Priority (10) added to the records. Check var.ses_mx_record definition.
  records = [
    "10 ${var.ses_mx_record}" 
  ]
}

# --- Missing Records (Please ensure these are also using local.zone_ids[each.value]) ---

# SES DKIM CNAME Records 
resource "aws_route53_record" "ses_dkim_records" {
  count = length(local.dkim_records_data)

  # Zone ID reference using the domain name (needs different logic since it uses 'count')
  zone_id = local.zone_ids[local.dkim_records_data[count.index].domain_name]

  name    = "${local.dkim_records_data[count.index].token_value}._domainkey"
  type    = "CNAME"
  ttl     = 600
  records = ["${local.dkim_records_data[count.index].token_value}.dkim.amazonses.com"]
}

# SPF Record (TXT)
resource "aws_route53_record" "client_spf_record" {
  for_each = local.active_domains
  zone_id = local.zone_ids[each.value] 
  name    = each.key
  type    = "TXT"
  ttl     = 600
  records = [
    "v=spf1 include:amazonses.com ~all",
  ]
}

# DMARC Record (TXT)
resource "aws_route53_record" "client_dmarc_record" {
  for_each = local.active_domains
  zone_id = local.zone_ids[each.value] 
  name    = "_dmarc.${each.key}"
  type    = "TXT"
  ttl     = 600
  records = [
    "v=DMARC1; p=none; rua=mailto:dmarc-reports@${each.key}; pct=100; adkim=r; aspf=r",
  ]
}

# Custom MAIL FROM for MX Record 
resource "aws_route53_record" "client_mail_from_mx" {
  for_each = local.active_domains
  zone_id = local.zone_ids[each.value] 
  name    = var.mail_from_domains[each.key]
  type    = "MX"
  ttl     = 600
  records = [
    "10 feedback-smtp.${data.aws_region.current.name}.amazonaws.com", 
  ]
}

# Custom MAIL FROM for SPF TXT Record
resource "aws_route53_record" "client_mail_from_txt" {
  for_each = local.active_domains
  zone_id = local.zone_ids[each.value] 
  name    = var.mail_from_domains[each.key]
  type    = "TXT"
  ttl     = 600
  records = [
    "v=spf1 include:amazonses.com ~all",
  ]
}