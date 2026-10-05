output "private_ips" {
  description = "Map of endpoint key => private IP"
  value       = { for k, pe in azurerm_private_endpoint.this : k => pe.private_service_connection[0].private_ip_address }
}