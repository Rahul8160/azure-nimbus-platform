output "vnet_ids" {
  description = "Map of vnet key => VNet ID"
  value       = { for k, v in azurerm_virtual_network.this : k => v.id }
}

output "vnet_names" {
  description = "Map of vnet key => VNet name"
  value       = { for k, v in azurerm_virtual_network.this : k => v.name }
}

output "subnet_ids" {
  description = "Map of \"vnet/subnet\" => subnet ID (e.g. spoke/snet-aks)"
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "nsg_ids" {
  description = "Map of \"vnet/subnet\" => NSG ID"
  value       = { for k, n in azurerm_network_security_group.this : k => n.id }
}