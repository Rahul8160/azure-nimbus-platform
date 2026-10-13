output "private_ips" {
  description = "Map of firewall key => private IP (the next hop for route tables)"
  value       = { for k, fw in azurerm_firewall.firewall : k => fw.ip_configuration[0].private_ip_address }
}

output "public_ips" {
  description = "Map of firewall key => public egress IP"
  value       = { for k, fw in var.firewalls : k => azurerm_public_ip.firewall["${k}/data"].ip_address }
}