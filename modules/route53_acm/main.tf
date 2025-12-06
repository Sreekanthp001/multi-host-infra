# modules/route53_acm/main.tf

# 1. Hosted Zone Creation (One Zone per Domain)
# We use a 'for_each' loop to handle multiple clients easily.
resource "aws_route53_zone" "client_zone" {
  for_each = toset(var.domain_names)
  name     = each.key

  tags = {
    Name = "ClientZone-${each.key}"
  }
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
    for dvo in aws_acm_certificate.client_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      
      root_domain = coalesce(
        lookup(aws_route53_zone.client_zone, dvo.domain_name, null),
        lookup(aws_route53_zone.client_zone, replace(dvo.domain_name, /^\*\./, ""), null)
      )

      zone_id = aws_route53_zone.client_zone[
        # Conditional to handle the root domain vs. wildcard domain
        contains(var.domain_names, dvo.domain_name) ? dvo.domain_name : split(".", dvo.domain_name)[1] == "com" ? dvo.domain_name : join(".", slice(split(".", dvo.domain_name), length(split(".", dvo.domain_name)) - 2, length(split(".", dvo.domain_name))))
      ].zone_id
      
      # Simplified and most reliable fix for this specific case (assuming only TLDs like .com, .net, etc.)
      root_domain_key = replace(dvo.domain_name, /^\*\./, "")

      # Final Corrected Line
      zone_id = aws_route53_zone.client_zone[
          # This extracts "example.com" from "*.example.com" or keeps "example.com"
          replace(dvo.domain_name, /^\*\./, "") 
      ].zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  zone_id         = each.value.zone_id
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