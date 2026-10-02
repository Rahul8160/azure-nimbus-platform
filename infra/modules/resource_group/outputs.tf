output "names" {
  description = "Map of logical key => resource group name"
  value       = { for k, rg in azurerm_resource_group.this : k => rg.name }
}

output "ids" {
  description = "Map of logical key => resource group ID"
  value       = { for k, rg in azurerm_resource_group.this : k => rg.id }
}

output "locations" {
  description = "Map of logical key => location"
  value       = { for k, rg in azurerm_resource_group.this : k => rg.location }
}