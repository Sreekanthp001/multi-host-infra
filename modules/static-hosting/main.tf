// 1. S3 Bucket for Static Content
resource "aws_s3_bucket" "content" {
  bucket = "${var.s3_prefix}-${var.client_id}-${var.s3_suffix}"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.content.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

// 2. AWS Certificate Manager (ACM) for HTTPS
// Creates SSL certificate for the client domain.
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name 
  
  subject_alternative_names = ["www.${var.domain_name}"] 
  
  validation_method = "DNS"
  
  tags = {
    Name = "${var.client_id}-static-cert"
  }
}

// 3. Route 53 Hosted Zone for the Client Domain
resource "aws_route53_zone" "client_zone" {
  name = var.domain_name
}

// 4. ACM Validation Record
// Creates the CNAME record in Route 53 to validate the ACM certificate.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for domain_validation in aws_acm_certificate.cert.domain_validation_options : domain_validation.domain_name => {
      name   = domain_validation.resource_record_name
      record = domain_validation.resource_record_value
      type   = domain_validation.resource_record_type
    }
  }

  zone_id = aws_route53_zone.client_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

// 5. CloudFront Origin Access Identity (OAI)
// Used to restrict S3 bucket access only to CloudFront.
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.domain_name} static hosting"
}

// 6. S3 Bucket Policy (Restricts access to the OAI)
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid    = "AllowCloudFrontRead"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.content.arn}/*",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.content.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

// 7. CloudFront Distribution (CDN)
// modules/static-hosting/main.tf

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  
  // FIX 2: Use var.domain_name (or your actual variable name)
  comment             = "CDN for static client: ${var.domain_name}"
  
  default_root_object = "index.html"

  origin {
    domain_name           = aws_s3_bucket.content.bucket_regional_domain_name
    origin_id             = aws_s3_bucket.content.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.content.id
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    // FIX 1: This block MUST be inside default_cache_behavior
    forwarded_values {
      query_string = false 
      
      cookies {
        forward = "none" 
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method             = "sni-only"
  }

  // FIX 2: Use var.domain_name
  aliases = [var.domain_name, "www.${var.domain_name}"]
}

// 8. Route 53 Alias Record (Domain -> CloudFront)
resource "aws_route53_record" "root_alias" {
  zone_id = aws_route53_zone.client_zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_alias" {
  zone_id = aws_route53_zone.client_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = true
  }
}