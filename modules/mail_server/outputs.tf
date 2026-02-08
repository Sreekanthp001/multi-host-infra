output "mail_server_ip" {
  value = aws_eip.mail_eip.public_ip
}

output "mail_server_hostname" {
  value = "mx.${var.main_domain}"
}
