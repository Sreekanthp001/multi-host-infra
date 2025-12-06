# modules/route53_acm/outputs.tt
output "acm_certificate_arn" {
  description = "The ARN of the issued ACM certificate."
  value       = aws_acm_certificate.client_cert.arn
}
output "hosted_zone_ids" {
  description = "Map of domain name to Hosted Zone ID"
  value       = { for k, v in aws_route53_zone.client_zone : k => v.zone_id }
}

output "name_servers" {
  description = "Map of domain name to AWS Name Servers (for external delegation)"
  value       = { for k, v in aws_route53_zone.client_zone : k => v.name_servers }
}