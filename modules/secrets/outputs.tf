# modules/secrets/outputs.tf

output "secret_arns" {
  value = { for k, v in aws_secretsmanager_secret.client_secrets : k => v.arn }
}
