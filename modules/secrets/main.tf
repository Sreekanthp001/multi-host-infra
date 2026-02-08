# modules/secrets/main.tf
# Secrets Manager Configuration
# Addresses: Manager's Requirement #5 - Security (No hard-coded secrets)

resource "random_password" "db_password" {
  for_each = var.client_domains
  length   = 16
  special  = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "api_key" {
  for_each = var.client_domains
  length   = 32
  special  = false
}

resource "aws_secretsmanager_secret" "client_secrets" {
  for_each = var.client_domains
  
  name        = "${var.project_name}/${each.key}/app-secrets"
  description = "Application secrets for ${each.key}"
  recovery_window_in_days = 0 # Force delete for demo purposes, use 7-30 for prod
  
  tags = {
    Client      = each.key
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "client_secrets" {
  for_each  = var.client_domains
  secret_id = aws_secretsmanager_secret.client_secrets[each.key].id
  
  secret_string = jsonencode({
    database_password = random_password.db_password[each.key].result
    api_key           = random_password.api_key[each.key].result
    domain            = each.value.domain
  })
}
