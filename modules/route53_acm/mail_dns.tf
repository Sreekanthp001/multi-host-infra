# 1. Primary A Record for the Mail Server (mx.primarydomain.com)
resource "aws_route53_record" "mail_server_a_record" {
  # count value must be known at plan time. var.main_domain is passed as a string/variable,
  # but mail_server_ip is a resource attribute (EIP) known only after apply.
  # Removing the IP check to fix the "Invalid count argument" error.
  count   = var.main_domain != "" ? 1 : 0
  
  zone_id = local.zone_ids[var.main_domain]
  name    = "mx.${var.main_domain}"
  type    = "A"
  ttl     = 300
  records = [var.mail_server_ip]
}

# 2. MX Records for Client Domains
resource "aws_route53_record" "client_mx" {
  for_each = local.all_domains
  zone_id  = local.zone_ids[each.value.domain]
  name     = each.value.domain
  type     = "MX"
  ttl      = 300
  records  = ["10 mx.webhizzy.in."]
}

# 3. SPF Records for Client Domains
resource "aws_route53_record" "client_spf" {
  for_each = local.all_domains
  zone_id  = local.zone_ids[each.value.domain]
  name     = each.value.domain
  type     = "TXT"
  ttl      = 300
  # The value here (mail_server_ip) is known after apply, which is fine for the records attribute
  records  = ["v=spf1 mx ip4:${var.mail_server_ip} -all"]
}

# 4. DMARC Records for Client Domains
resource "aws_route53_record" "client_dmarc" {
  for_each = local.all_domains
  zone_id  = local.zone_ids[each.value.domain]
  name     = "_dmarc.${each.value.domain}"
  type     = "TXT"
  ttl      = 300
  records  = ["v=DMARC1; p=quarantine; adkim=s; aspf=s"]
}
