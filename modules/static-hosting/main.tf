# 1. S3 Bucket for Static Content
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

# 2. CloudFront Origin Access Identity (OAI)
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.domain_name} static hosting"
}

# 3. S3 Bucket Policy (Restricts access to the OAI)
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid     = "AllowCloudFrontRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.content.arn}/*"]
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

# 4. CloudFront Distribution (CDN)
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for static client: ${var.domain_name}"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.content.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.content.id
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
    acm_certificate_arn            = var.acm_certificate_arn # Passed from root
    ssl_support_method             = "sni-only"
  }

  aliases = [var.domain_name, "www.${var.domain_name}"]
}

# 5. Route 53 Alias Records (Domain -> CloudFront)
resource "aws_route53_record" "root_alias" {
  zone_id = var.hosted_zone_id # Passed from root
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_alias" {
  zone_id = var.hosted_zone_id # Passed from root
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = true
  }
}