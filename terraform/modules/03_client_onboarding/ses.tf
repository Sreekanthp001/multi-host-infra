# 1. SES Domain Identity Verification
resource "aws_ses_domain_identity" "client" {
  domain = var.domain_name
}

# 2. DKIM (DomainKeys Identified Mail) Records
# SES requires 3 CNAME records for DKIM to verify sending identity
resource "aws_ses_domain_identity_dkim" "client" {
  domain = aws_ses_domain_identity.client.domain
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = aws_route53_zone.client.zone_id
  name    = "${element(aws_ses_domain_identity_dkim.client.dkim_tokens, count.index)}._domainkey.${var.domain_name}"
  type    = "CNAME"
  records = ["${element(aws_ses_domain_identity_dkim.client.dkim_tokens, count.index)}.dkim.amazonses.com"]
  ttl     = 1800
}

# 3. SPF (Sender Policy Framework) Record
# This TXT record ensures emails sent via SES are authorized by the domain
resource "aws_route53_record" "spf" {
  zone_id = aws_route53_zone.client.zone_id
  name    = var.domain_name
  type    = "TXT"
  records = ["v=spf1 include:amazonses.com ~all"]
  ttl     = 1800
}

# 4. MX Record for Inbound Email (SES)
# Directs incoming mail to the AWS SES endpoint for the region
resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.client.zone_id
  name    = var.domain_name
  type    = "MX"
  records = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
  ttl     = 3600
}

# Data source for current region (required for the MX record endpoint)
data "aws_region" "current" {}