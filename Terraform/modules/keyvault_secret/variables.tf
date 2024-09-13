variable "secret_name" {
  description = "Environment name"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "keyvault_name" {
  description = "Environment name"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "keyvault_resource_group" {
  description = "Environment name"
  type        = string
  nullable    = false
  sensitive   = true
}