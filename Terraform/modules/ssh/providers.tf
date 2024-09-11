terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}