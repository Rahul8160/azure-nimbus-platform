output "ids" {
  value = { for k, v in azurerm_key_vault.this : k => v.id }
}

output "uris" {
  description = "e.g. https://kv-nimbus-f78654.vault.azure.net/"
  value       = { for k, v in azurerm_key_vault.this : k => v.vault_uri }
}