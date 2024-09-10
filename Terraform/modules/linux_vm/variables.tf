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

variable subnet_name {
    description = "Name of the subnet to associate the VM"
    type = string
}

variable virtual_network_name {
    description = "Name of the virtual network to associate the VM"
    type = string
}

variable vm_name {
    description = "Name of the virtual machines"
    type = string
}

variable "component_name" {
  type = string
}

variable "username" {
  type = string
}

variable "public_ssh_key" {
  type = string
}

#Optional
variable public_ip_id {
    description = "(Optional) public IP address to associate"
    type = string
    default = null
    nullable = true
}
