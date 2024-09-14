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

# TODO: Move into Linux_VM module making public ip an optional flag
# Create public IPs
resource "azurerm_public_ip" "primary_controller_public_ip" {
  name                = "pip-ath-aks-con-01-${lower(var.environment)}-${lower(var.primary_location)}"
  location            = azurerm_resource_group.primary_rg.location
  resource_group_name = azurerm_resource_group.primary_rg.name
  allocation_method   = "Static"
}

# Create public IPs
resource "azurerm_public_ip" "primary_worker_1_public_ip" {
  name                = "pip-ath-aks-work-01-${lower(var.environment)}-${lower(var.primary_location)}"
  location            = azurerm_resource_group.primary_rg.location
  resource_group_name = azurerm_resource_group.primary_rg.name
  allocation_method   = "Static"
}

# Create public IPs
resource "azurerm_public_ip" "primary_worker_2_public_ip" {
  name                = "pip-ath-aks-work-02-${lower(var.environment)}-${lower(var.primary_location)}"
  location            = azurerm_resource_group.primary_rg.location
  resource_group_name = azurerm_resource_group.primary_rg.name
  allocation_method   = "Static"
}

# Create Network Security Group and rule

resource "azurerm_network_security_group" "linux_vm_nsg" {
  name                = "nsg-ath-aks-${lower(var.environment)}-${lower(var.primary_location)}"
  location            = var.primary_location
  resource_group_name = azurerm_resource_group.primary_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH"
    priority                   = 1200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


module "ssh_public_key" {
  source                  = "./modules/keyvault_secret"
  keyvault_resource_group = var.sshkey_keyvault_resource_group_name
  keyvault_name           = var.sshkey_keyvault_name
  secret_name             = var.sshkey_secret_name
}

module "primary_controller_linux_vm" {
  source                      = "./modules/linux_vm"
  component_name              = "ath-aks"
  public_ssh_key              = module.ssh_public_key.secret_value
  virtual_network_name        = azurerm_virtual_network.primary_vnet.name
  location                    = var.primary_location
  username                    = "aatrisgn"
  environment                 = var.environment
  vm_name                     = "con-01"
  subnet_name                 = local.controller_subnet_name
  resource_group_name         = azurerm_resource_group.primary_rg.name
  public_ip_id                = azurerm_public_ip.primary_controller_public_ip.id
  network_security_group_name = azurerm_network_security_group.linux_vm_nsg.name
  depends_on                  = [azurerm_resource_group.primary_rg, azurerm_virtual_network.primary_vnet, azurerm_subnet.primary_controller_subnet]
}

module "primary_worker_1_linux_vm" {
  source                      = "./modules/linux_vm"
  component_name              = "ath-aks"
  public_ssh_key              = module.ssh_public_key.secret_value
  virtual_network_name        = azurerm_virtual_network.primary_vnet.name
  location                    = var.primary_location
  username                    = "aatrisgn"
  environment                 = var.environment
  vm_name                     = "work-01"
  subnet_name                 = local.worker_subnet_name
  resource_group_name         = azurerm_resource_group.primary_rg.name
  public_ip_id                = azurerm_public_ip.primary_worker_1_public_ip.id
  network_security_group_name = azurerm_network_security_group.linux_vm_nsg.name
  depends_on                  = [azurerm_resource_group.primary_rg, azurerm_virtual_network.primary_vnet, azurerm_subnet.primary_controller_subnet]
}

module "primary_worker_2_linux_vm" {
  source                      = "./modules/linux_vm"
  component_name              = "ath-aks"
  public_ssh_key              = module.ssh_public_key.secret_value
  virtual_network_name        = azurerm_virtual_network.primary_vnet.name
  location                    = var.primary_location
  username                    = "aatrisgn"
  environment                 = var.environment
  vm_name                     = "work-02"
  subnet_name                 = local.worker_subnet_name
  resource_group_name         = azurerm_resource_group.primary_rg.name
  public_ip_id                = azurerm_public_ip.primary_worker_2_public_ip.id
  network_security_group_name = azurerm_network_security_group.linux_vm_nsg.name
  depends_on                  = [azurerm_resource_group.primary_rg, azurerm_virtual_network.primary_vnet, azurerm_subnet.primary_controller_subnet]
}
