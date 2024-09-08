variable "primary_location" {
  description = "Default region for provider"
  type        = string
  nullable    = false
  validation {
    condition     = var.location == "westeurope" || var.location == "northeurope"
    error_message = "Only 'westeurope' and 'northeurope' is allowed values."
  }
}

variable "secondary_location" {
  description = "Default region for provider"
  type        = string
  nullable    = false
  validation {
    condition     = var.location == "westeurope" || var.location == "northeurope"
    error_message = "Only 'westeurope' and 'northeurope' is allowed values."
  }
}

variable "tertiary_location" {
  description = "Default region for provider"
  type        = string
  nullable    = true
  validation {
    condition     = var.location == "westeurope" || var.location == "northeurope"
    error_message = "Only 'westeurope' and 'northeurope' is allowed values."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  nullable    = false
  validation {
    condition     = var.environment == "dev" || var.environment == "tst" || var.environment == "sta" || var.environment == "prd"
    error_message = "Only DEV, TST, STA and PRD is allowed values."
  }
}