# modules/route53_acm/outputs.tt
output "acm_certificate_arn" {
  description = "The ARN of the issued ACM certificate."
  value       = aws_acm_certificate.client_cert.arn
}
output "hosted_zone_ids" {
  description = "The IDs of the created Route 53 Hosted Zones"
  value       = {
    
    for k, v in aws_route53_zone.client_hosted_zones : v.name => v.zone_id
  }
}

output "name_servers" {
  description = "The Name Servers for the created Hosted Zones"
  value       = {
    for k, v in aws_route53_zone.client_hosted_zones : v.name => v.name_servers
  }
}

output "acm_validation_resource" {
  description = "The ACM validation resource object for dependency chaining."
  # aws_acm_certificate_validation.cert_validation రిసోర్స్ ఆబ్జెక్ట్ ను పాస్ చేస్తుంది
  value = aws_acm_certificate_validation.cert_validation
}