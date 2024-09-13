data "azurerm_key_vault" "existing_keyvault" {
  name                = var.keyvault_name
  resource_group_name = var.keyvault_resource_group
}

data "azurerm_key_vault_secret" "existing_secret" {
  name         = var.secret_name
  key_vault_id = data.azurerm_key_vault.existing_keyvault.id
}
