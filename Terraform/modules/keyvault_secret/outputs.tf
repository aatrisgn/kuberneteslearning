output "secret_value" {
  value = data.azurerm_key_vault_secret.existing_secret.value
}