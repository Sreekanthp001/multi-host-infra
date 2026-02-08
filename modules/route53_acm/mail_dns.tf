# Automation for Client Domain Mail Records (MX, SPF, DMARC)
# This uses the Elastic IP from the mail server module

variable "mail_server_ip" {
  type        = string
  description = "Public IP of the primary mail server (mx.webhizzy.in)"
}

resource "aws_route53_record" "client_mx" {
  for_each = local.all_domains
  zone_id  = local.zone_ids[each.value.domain]
  name     = each.value.domain
  type     = "MX"
  ttl      = 300
  records  = ["10 mx.webhizzy.in."]
}

resource "aws_route53_record" "client_spf" {
  for_each = local.all_domains
  zone_id  = local.zone_ids[each.value.domain]
  name     = each.value.domain
  type     = "TXT"
  ttl      = 300
  records  = ["v=spf1 mx ip4:${var.mail_server_ip} -all"]
}

resource "aws_route53_record" "client_dmarc" {
  for_each = local.all_domains
  zone_id  = local.zone_ids[each.value.domain]
  name     = "_dmarc.${each.value.domain}"
  type     = "TXT"
  ttl      = 300
  records  = ["v=DMARC1; p=quarantine; adkim=s; aspf=s"]
}
