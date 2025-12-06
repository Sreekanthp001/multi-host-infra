# modules/route53_acm/main.tf

# 1. Hosted Zone Creation (One Zone per Domain)
# We use a 'for_each' loop to handle multiple clients easily.
resource "aws_route53_zone" "client_zone" {
  for_each = toset(var.domain_names) # var.domain_names contains ["venturemond.com", "sampleclient.com"]
  name     = each.key # The key of the map is "venturemond.com"
}

# 2. ACM Certificate Request
# This certificate covers all domains and their wildcards (*.domain.com)
resource "aws_acm_certificate" "client_cert" {
  # REMOVE 'provider = aws.us_east_1' HERE. 
  # It will now implicitly use the provider passed from the root module.
  domain_name       = var.domain_names[0] 
  validation_method = "DNS"

  subject_alternative_names = flatten([
    for domain in var.domain_names : [domain, "*.${domain}"]
  ])

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "MultiClient-Wildcard-Cert" }
}

# 3. Create DNS Validation Records in Route53
# This resource automatically creates the CNAME records required by ACM
# modules/route53_acm/main.tf

# ... (lines 1-36 remain the same)

# 3. Create DNS Validation Records in Route53
resource "aws_route53_record" "cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.client_cert.domain_validation_options : dvo.domain_name => dvo
  }

  allow_overwrite = true
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  ttl             = 60
  records         = [each.value.resource_record_value]

  # CRITICAL FIX: Strip wildcard prefix and ensure no trailing dot in the key lookup
  zone_id = aws_route53_zone.client_zone[
    # 1. Remove the wildcard prefix "*.":
    # 2. Use trim to remove a possible trailing dot, ensuring the key matches the zone definition
    trim(replace(each.value.domain_name, "^\\*\\.", ""), ".")
  ].zone_id
}
# 4. Wait for ACM Validation to Complete
# This is a critical blocker. Terraform will pause here until the certificate status is 'ISSUED'.
resource "aws_acm_certificate_validation" "cert_validation" {
  # REMOVE 'provider = aws.us_east_1' HERE for the same reason
  certificate_arn         = aws_acm_certificate.client_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_records : record.fqdn]

  timeouts {
    create = "15m" 
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