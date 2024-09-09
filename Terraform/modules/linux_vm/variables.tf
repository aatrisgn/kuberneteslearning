variable "location" {
  description = "Default region for provider"
  type        = string
  nullable    = false
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

variable resource_group_name {
    description = "resource group name"
    type = string
}

variable subnet_id {
    description = "ID of the subnet to associate the VM"
    type = string
}

variable "component_name" {
  type = string
  nullable = false
}

#Optional
variable public_ip_id {
    description = "(Optional) public IP address to associate"
    type = string
}
