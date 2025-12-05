# Resources only provisioned if site_type is 'static'
resource "aws_s3_bucket" "static_site" {
  count  = var.site_type == "static" ? 1 : 0
  bucket = var.domain_name # Use domain name for bucket name
  
  # S3 best practice: Block all public access
  acl    = "private" 

  tags = {
    Name = "${var.project_name}-Static-Bucket-${var.domain_name}"
  }
}

# S3 Bucket Policy (Allows CloudFront OAI to read objects)
resource "aws_s3_bucket_policy" "static_site" {
  count  = var.site_type == "static" ? 1 : 0
  bucket = aws_s3_bucket.static_site[0].id
  policy = data.aws_iam_policy_document.s3_policy[0].json
}

# OAI (Origin Access Identity) for CloudFront to access S3 privately
resource "aws_cloudfront_origin_access_identity" "static_site" {
  count = var.site_type == "static" ? 1 : 0
  comment = "OAI for ${var.domain_name}"
}

data "aws_iam_policy_document" "s3_policy" {
  count = var.site_type == "static" ? 1 : 0
  statement {
    sid = "AllowCloudFrontOAIRead"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site[0].arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static_site[0].iam_arn]
    }
  }

  statement {
    sid    = "AllowRootBucketList"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.static_site[0].arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static_site[0].iam_arn]
    }
  }
}

# CloudFront Distribution (CDN)
resource "aws_cloudfront_distribution" "static_site" {
  count  = var.site_type == "static" ? 1 : 0
  
  enabled             = true
  default_root_object = "index.html"
  comment             = "CDN for ${var.domain_name}"
  
  origin {
    domain_name = aws_s3_bucket.static_site[0].bucket_regional_domain_name
    origin_id   = "s3-${var.domain_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.static_site[0].cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-${var.domain_name}"
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
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = "sni-only"
  }
}