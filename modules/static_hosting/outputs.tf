# modules/static_hosting/outputs.tf

output "cloudfront_domain_names" {
  description = "The domain names assigned by CloudFront for each client"
  value       = { for k, v in aws_cloudfront_distribution.s3_dist : k => v.domain_name }
}

output "cloudfront_hosted_zone_ids" {
  description = "The CloudFront Hosted Zone IDs (required for Route53 Alias records)"
  value       = { for k, v in aws_cloudfront_distribution.s3_dist : k => v.hosted_zone_id }
}

output "s3_bucket_names" {
  description = "The names of the S3 buckets used for static hosting"
  value       = { for k, v in aws_s3_bucket.static_bucket : k => v.id }
}