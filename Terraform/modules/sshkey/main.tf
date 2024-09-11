resource "tls_private_key" "ssh_key_set" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "azure_secret" {
  name         = var.secret_key_name
  value        = tls_private_key.example.private_key_pem
  key_vault_id = data.azurerm_key_vault.existing_keyvault.id
}