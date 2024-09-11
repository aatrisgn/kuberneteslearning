# Configure the Azure provider
terraform {
  #Will automatically be provided during deployment via -backend-config arguments
  required_version = ">= 1.9.5"

  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.0"
    }
  }
}

provider "azurerm" {
  use_oidc = true
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "primary_rg" {
  name     = "rg-ath-aks-${lower(var.environment)}-${lower(var.primary_location)}"
  location = var.primary_location
}

resource "azurerm_resource_group" "secondary_rg" {
  name     = "rg-ath-aks-${lower(var.environment)}-${lower(var.secondary_location)}"
  location = var.secondary_location
}

resource "azurerm_virtual_network" "primary_vnet" {
  name                = "vnet-ath-aks-${lower(var.environment)}-${lower(var.primary_location)}"
  location            = azurerm_resource_group.primary_rg.location
  resource_group_name = azurerm_resource_group.primary_rg.name
  address_space       = ["10.10.0.0/16"]
}

# Create subnet
resource "azurerm_subnet" "primary_controller_subnet" {
  name                 = local.controller_subnet_name
  resource_group_name  = azurerm_resource_group.primary_rg.name
  virtual_network_name = azurerm_virtual_network.primary_vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# Create subnet
resource "azurerm_subnet" "primary_worker_subnet" {
  name                 = local.worker_subnet_name
  resource_group_name  = azurerm_resource_group.primary_rg.name
  virtual_network_name = azurerm_virtual_network.primary_vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_virtual_network" "secondary_vnet" {
  name                = "vnet-ath-aks-${lower(var.environment)}-${lower(var.primary_location)}"
  location            = azurerm_resource_group.secondary_rg.location
  resource_group_name = azurerm_resource_group.secondary_rg.name
  address_space       = ["10.11.0.0/16"]
}

resource "azurerm_subnet" "secondary_controller_subnet" {
  name                 = local.controller_subnet_name
  resource_group_name  = azurerm_resource_group.secondary_rg.name
  virtual_network_name = azurerm_virtual_network.secondary_vnet.name
  address_prefixes     = ["10.11.1.0/24"]
}

# Create subnet
resource "azurerm_subnet" "secondary_worker_subnet" {
  name                 = local.worker_subnet_name
  resource_group_name  = azurerm_resource_group.secondary_rg.name
  virtual_network_name = azurerm_virtual_network.secondary_vnet.name
  address_prefixes     = ["10.11.2.0/24"]
}

resource "azurerm_virtual_network_peering" "peer_primary_to_secondary" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.primary_rg.name
  virtual_network_name      = azurerm_virtual_network.primary_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.secondary_vnet.id
}

resource "azurerm_virtual_network_peering" "peer_secondary_to_primary" {
  name                      = "peer2to1"
  resource_group_name       = azurerm_resource_group.secondary_rg.name
  virtual_network_name      = azurerm_virtual_network.secondary_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.primary_vnet.id
}

# Create public IPs
resource "azurerm_public_ip" "primary_public_ip" {
  name                = "pip-ath-aks-${lower(var.environment)}-${lower(var.primary_location)}"
  location            = azurerm_resource_group.primary_rg.location
  resource_group_name = azurerm_resource_group.primary_rg.name
  allocation_method   = "Static"
}
# Create public IPs
resource "azurerm_public_ip" "secondary_public_ip" {
  name                = "pip-ath-aks-${lower(var.environment)}-${lower(var.secondary_location)}"
  location            = azurerm_resource_group.secondary_rg.location
  resource_group_name = azurerm_resource_group.secondary_rg.name
  allocation_method   = "Static"
}

resource "azurerm_key_vault" "key_vault" {
  resource_group_name = azurerm_resource_group.primary_rg.name
  location            = azurerm_resource_group.primary_rg.location
  name                = "kvathaksdevwe"
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

module "primary_ssh_key" {
  source = "./modules/sshkey"

  secret_key_name     = "primarysshkey"
  resource_group_name = azurerm_resource_group.primary_rg.name
  keyvault_name       = azurerm_key_vault.key_vault.name

  depends_on = [azurerm_key_vault.key_vault]
}

module "secondary_ssh_key" {
  source = "./modules/sshkey"

  secret_key_name     = "secondarysshkey"
  resource_group_name = azurerm_resource_group.primary_rg.name
  keyvault_name       = azurerm_key_vault.key_vault.name

  depends_on = [azurerm_key_vault.key_vault]
}

module "primary_controller_linux_vm" {
  source               = "./modules/linux_vm"
  component_name       = "ath-aks"
  public_ssh_key       = module.primary_ssh_key.public_key
  virtual_network_name = azurerm_virtual_network.primary_vnet.name
  location             = var.primary_location
  username             = "aatrisgn"
  environment          = var.environment
  vm_name              = "01"
  subnet_name          = local.controller_subnet_name
  resource_group_name  = azurerm_resource_group.primary_rg.name
  depends_on           = [azurerm_resource_group.primary_rg, azurerm_virtual_network.primary_vnet, azurerm_subnet.primary_controller_subnet]
}

module "secondary_controller_linux_vm" {
  source               = "./modules/linux_vm"
  component_name       = "ath-aks"
  public_ssh_key       = module.secondary_ssh_key.public_key
  virtual_network_name = azurerm_virtual_network.secondary_vnet.name
  location             = var.secondary_location
  username             = "aatrisgn"
  environment          = var.environment
  vm_name              = "01"
  subnet_name          = local.controller_subnet_name
  resource_group_name  = azurerm_resource_group.secondary_rg.name
  depends_on           = [azurerm_resource_group.secondary_rg, azurerm_virtual_network.secondary_vnet, azurerm_subnet.secondary_controller_subnet]
}
