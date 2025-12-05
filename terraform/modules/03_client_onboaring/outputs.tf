output "hosted_zone_name_servers" {
  description = "The Name Servers for the Route53 Hosted Zone. Must be updated in your domain registrar."
  value       = aws_route53_zone.client.name_servers
}

output "s3_bucket_name" {
  description = "The S3 bucket name for static hosting."
  value       = var.site_type == "static" ? aws_s3_bucket.static_site[0].bucket : "N/A"
}

output "cloudfront_distribution_id" {
  description = "The CloudFront Distribution ID for invalidation (used in CI/CD)."
  value       = var.site_type == "static" ? aws_cloudfront_distribution.static_site[0].id : "N/A"
}