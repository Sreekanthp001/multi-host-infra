# modules/alb/variables.tf

variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "acm_certificate_arn" {
  type = string
  description = "The ARN of the ACM certificate to use for the HTTPS listener."
}

# 🛑 కొత్త వేరియబుల్: ACM ధృవీకరణ రిసోర్స్ ను పాస్ చేయడానికి
variable "acm_validation_resource" {
  type        = any # ఇది aws_acm_certificate_validation రిసోర్స్ ఆబ్జెక్ట్ ను తీసుకుంటుంది
  description = "The ACM validation resource used to enforce dependency."
}