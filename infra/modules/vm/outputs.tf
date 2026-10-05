output "private_ips" {
  value = { for k, n in azurerm_network_interface.nic : k => n.private_ip_address }
}

output "names" {
  value = { for k, v in azurerm_linux_virtual_machine.vm : k => v.name }
}


output "principal_ids" {
  description = "Object ID of each VM's managed identity"
  value       = { for k, v in azurerm_linux_virtual_machine.vm : k => v.identity[0].principal_id }
}