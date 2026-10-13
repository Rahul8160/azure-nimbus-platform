output "ids" {
  value = { for k, rt in azurerm_route_table.route_table : k => rt.id }
}