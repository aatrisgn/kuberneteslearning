data "azurerm_resource_group" "existing_resource_group" {
    name = var.resource_group_name
}

data "azurerm_subnet" "vm_subnet" {
    name = var.subnet_name
    virtual_network_name = var.virtual_network_name
    resource_group_name = var.resource_group_name
}