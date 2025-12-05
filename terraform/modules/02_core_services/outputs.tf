output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "https_listener_arn" {
  description = "ARN of the ALB HTTPS Listener (Port 443) for routing rules."
  value       = aws_lb_listener.https.arn
}

output "acm_certificate_arn" {
  description = "ARN of the wildcard certificate created in this module."
  value       = aws_acm_certificate.wildcard.arn
}

output "acm_validation_records" {
  description = "The CNAME records required for DNS validation of the ACM certificate."
  value = aws_acm_certificate.wildcard.domain_validation_options
}

output "ecs_cluster_id" {
  description = "ID of the main ECS Cluster."
  value       = aws_ecs_cluster.main.id
}


output "ecs_tasks_sg_id" {
  description = "Security Group ID for ECS tasks (allows traffic from ALB)."
  value       = aws_security_group.ecs_tasks.id
}

output "github_actions_role_arn" {
  description = "The IAM Role ARN for GitHub Actions OIDC."
  value       = aws_iam_role.github_actions.arn
}