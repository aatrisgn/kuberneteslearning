variable "primary_location" {
  description = "Default region for provider"
  type        = string
  nullable    = false
  validation {
    condition     = var.primary_location == "westeurope" || var.primary_location == "northeurope"
    error_message = "Only 'westeurope' and 'northeurope' is allowed values."
  }
}

variable "secondary_location" {
  description = "Default region for provider"
  type        = string
  nullable    = false
  validation {
    condition     = var.secondary_location == "westeurope" || var.secondary_location == "northeurope"
    error_message = "Only 'westeurope' and 'northeurope' is allowed values."
  }
}

variable "tertiary_location" {
  description = "Default region for provider"
  type        = string
  nullable    = false
  default     = "N/A"
  validation {
    condition     = var.tertiary_location == "N/A" || var.tertiary_location == "westeurope" || var.tertiary_location == "northeurope"
    error_message = "Only 'westeurope' and 'northeurope' is allowed values."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  nullable    = true
  validation {
    condition     = var.environment == "dev" || var.environment == "tst" || var.environment == "sta" || var.environment == "prd"
    error_message = "Only DEV, TST, STA and PRD is allowed values."
  }
}

variable "sshkey_secret_name" {
  description = "Environment name"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "sshkey_keyvault_name" {
  description = "Environment name"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "sshkey_keyvault_resource_group_name" {
  description = "Environment name"
  type        = string
  nullable    = false
  sensitive   = true
}
