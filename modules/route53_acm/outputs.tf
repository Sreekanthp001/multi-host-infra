# modules/route53_acm/outputs.tf

output "acm_certificate_arn" {
  description = "ARN of the generated SSL certificate"
  value       = aws_acm_certificate.client_cert.arn
}

output "acm_validation_resource" {
  description = "Validation object to ensure certs are ready before ALB uses them"
  value       = aws_acm_certificate_validation.cert_validation
}

output "hosted_zone_ids" {
  description = "Map of domain names to their Hosted Zone IDs"
  value       = { for k, v in aws_route53_zone.client_hosted_zones : v.name => v.zone_id }
}

output "name_servers" {
  description = "Name servers for the created hosted zones"
  value       = { for k, v in aws_route53_zone.client_hosted_zones : v.name => v.name_servers }
}

output "acm_validation_id" {
  value = aws_acm_certificate_validation.cert_validation.id
}