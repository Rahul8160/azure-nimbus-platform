output "listener_fqdns" {
  description = "Read-write listener: always points at the current primary. Apps should use this name."
  value       = { for k, fg in azurerm_mssql_failover_group.failover_group : k => "${fg.name}.database.windows.net" }
}