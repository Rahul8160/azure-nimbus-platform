output "server_ids" {
  value = { for k, s in azurerm_mssql_server.server : k => s.id }
}

output "server_fqdns" {
  description = "e.g. sql-nimbus-f786969.database.windows.net (what the app uses as SQL_SERVER)"
  value       = { for k, s in azurerm_mssql_server.server : k => s.fully_qualified_domain_name }
}

output "database_ids" {
  value = { for k, d in azurerm_mssql_database.database : k => d.id }
}