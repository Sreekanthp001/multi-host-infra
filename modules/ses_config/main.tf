resource "aws_ses_domain_identity" "client_ses_identity" {
  for_each = var.client_domains
  domain   = each.value
}

resource "aws_ses_domain_dkim" "client_ses_dkim" {
  for_each = var.client_domains
  domain   = aws_ses_domain_identity.client_ses_identity[each.key].domain
}

resource "aws_ses_receipt_rule_set" "main_rule_set" {
  rule_set_name = "multi-client-rules"
  
  depends_on = [
    aws_ses_domain_identity.client_ses_identity
  ]
}

resource "aws_ses_receipt_rule" "forwarding_rule" {
  for_each = var.client_domains
  name            = "${each.key}-forwarding-rule"
  rule_set_name   = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
  enabled         = true
  scan_enabled    = true
  
  recipients      = [each.value]

  
}