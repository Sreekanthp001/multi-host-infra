# modules/route53_acm/outputs.tt
output "acm_certificate_arn" {
  description = "The ARN of the issued ACM certificate."
  value       = aws_acm_certificate.client_cert.arn
}
output "hosted_zone_ids" {
  description = "The IDs of the created Route 53 Hosted Zones"
  value       = {
    # aws_route53_zone.client_zone ను aws_route53_zone.client_zone_final కు మార్చండి
    for k, v in aws_route53_zone.client_zone_final : v.name => v.zone_id
  }
}

output "name_servers" {
  description = "The Name Servers for the created Hosted Zones"
  value       = {
    # aws_route53_zone.client_zone ను aws_route53_zone.client_zone_final కు మార్చండి
    for k, v in aws_route53_zone.client_zone_final : v.name => v.name_servers
  }
}