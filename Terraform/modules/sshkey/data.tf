data "azurerm_key_vault" "existing_keyvault" {
    resource_group_name = var.resource_group_name
    name = var.keyvault_name
}