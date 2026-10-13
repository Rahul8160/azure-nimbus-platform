resource "azurerm_mssql_failover_group" "failover_group" {
  for_each = var.failover_groups

  name      = each.value.name
  server_id = each.value.primary_server_id
  databases = each.value.database_ids
  tags      = var.tags

  partner_server {
    id = each.value.secondary_server_id
  }

  # Automatic: if the primary region is unavailable for grace_minutes, Azure fails over
  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = each.value.grace_minutes
  }
}