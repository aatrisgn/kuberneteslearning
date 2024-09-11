# Create Network Security Group and rule

resource "azurerm_network_security_group" "linux_vm_nsg" {
  name                = "nsg-${lower(var.component_name)}-${lower(var.environment)}-${lower(var.location)}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.existing_resource_group.name

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
}

# Create network interface
resource "azurerm_network_interface" "linux_vm_nic" {
  name                = "nic-${lower(var.component_name)}-${lower(var.environment)}-${lower(var.location)}"
  location            = data.azurerm_resource_group.existing_resource_group.location
  resource_group_name = data.azurerm_resource_group.existing_resource_group.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = data.azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_id != null ? var.public_ip_id : null
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "linux_vm_association" {
  network_interface_id      = azurerm_network_interface.linux_vm_nic.id
  network_security_group_id = azurerm_network_security_group.linux_vm_nsg.id
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                  = "vm-${var.component_name}-${var.vm_name}-${lower(var.environment)}-${lower(var.location)}"
  location              = data.azurerm_resource_group.existing_resource_group.location
  resource_group_name   = data.azurerm_resource_group.existing_resource_group.name
  network_interface_ids = [azurerm_network_interface.linux_vm_nic.id]
  size                  = "Standard_B2als_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = var.public_ssh_key
  }
}
