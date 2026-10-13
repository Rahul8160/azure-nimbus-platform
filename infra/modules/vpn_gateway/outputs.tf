output "ids" {
  description = "Map of gateway key => gateway ID"
  value       = { for k, g in azurerm_virtual_network_gateway.gateway : k => g.id }
}

output "public_ips" {
  value = { for k, ip in azurerm_public_ip.gateway : k => ip.ip_address }
}