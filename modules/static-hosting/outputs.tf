output "s3_bucket_name" {
  description = "The S3 bucket name where the client must upload static assets."
  value       = aws_s3_bucket.content.id
}

output "cloudfront_domain_name" {
  description = "The CloudFront Domain Name (Testing URL)."
  value       = aws_cloudfront_distribution.cdn.domain_name
}