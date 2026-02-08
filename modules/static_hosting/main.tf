# modules/static_hosting/main.tf

# 1. S3 Bucket for Static Content
resource "aws_s3_bucket" "static_bucket" {
  for_each      = var.static_client_configs
  bucket        = "${var.project_name}-${each.key}-static-content"
  force_destroy = true # Allows clean deletion of non-empty buckets during testing
}

# 2. Origin Access Control (OAC)
# Ensures S3 bucket content is ONLY accessible through CloudFront.
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-oac-${var.project_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 3. CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_dist" {
  for_each = var.static_client_configs

  origin {
    domain_name              = aws_s3_bucket.static_bucket[each.key].bucket_regional_domain_name
    origin_id                = "S3-${each.key}"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [each.value.domain_name] # Links the client's custom domain

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${each.key}"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name   = "${var.project_name}-${each.key}-cf"
    Client = each.key
  }
}

# 4. S3 Bucket Policy to allow CloudFront access
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  for_each = var.static_client_configs
  bucket   = aws_s3_bucket.static_bucket[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.static_bucket[each.key].arn}/*"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_dist[each.key].arn
          }
        }
      }
    ]
  })
}