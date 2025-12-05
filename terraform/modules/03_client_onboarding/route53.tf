# 1. Route 53 Hosted Zone
resource "aws_route53_zone" "client" {
  name = var.domain_name

  tags = {
    Name = "${var.project_name}-Zone-${var.domain_name}"
  }
}

# 2. ACM Validation Records
# Find the specific validation records needed for THIS domain from the existing wildcard certificate
data "aws_acm_certificate" "wildcard" {
  domain = var.domain_name
  statuses   = ["ISSUED"]
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in data.aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => dvo
    if dvo.domain_name == var.domain_name || dvo.domain_name == "*.${var.domain_name}"
  }

  zone_id = aws_route53_zone.client.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

# 3. Primary A Record (Root domain)
resource "aws_route53_record" "root_alias" {
  zone_id = aws_route53_zone.client.zone_id
  name    = var.domain_name
  type    = "A"

  # Determine target based on site_type
  alias {
    name                   = var.site_type == "static" ? aws_cloudfront_distribution.static_site[0].domain_name : var.alb_dns_name
    zone_id = var.site_type == "static" ?
      aws_cloudfront_distribution.static_site[0].hosted_zone_id :
      data.aws_lb.main[0].zone_id

    evaluate_target_health = true
  }
  
  # Ensure CloudFront/ALB is available before creating the alias
  depends_on = [
    # Static hosting resources are defined in s3_static.tf
    # Dynamic hosting relies on the ALB being passed
    aws_cloudfront_distribution.static_site, 
    data.aws_lb.main
  ]
}

# Data source for the ALB's hosted zone ID (needed for Alias record)
data "aws_lb" "main" {
  count = var.alb_dns_name != null ? 1 : 0
  name  = split(".", var.alb_dns_name)[0]
}