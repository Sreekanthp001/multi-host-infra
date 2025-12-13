output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.aws_lb.main.dns_name
}