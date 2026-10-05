output "ids" {
  value = { for k, r in azurerm_container_registry.this : k => r.id }
}

output "login_servers" {
  description = "e.g. acrnimbusf78654.azurecr.io"
  value       = { for k, r in azurerm_container_registry.this : k => r.login_server }
}