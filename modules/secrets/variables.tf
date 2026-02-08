# modules/secrets/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "client_domains" {
  description = "Map of client domains for dynamic hosting"
  type        = map(any)
}
