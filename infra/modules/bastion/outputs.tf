output "ids" {
  value = { for k, b in azurerm_bastion_host.bastion : k => b.id }
}