locals {
  # Flatten servers -> databases. Key example: "main/ordersdb"
  databases = merge([
    for server_key, server in var.servers : {
      for db_name, db in server.databases :
      "${server_key}/${db_name}" => merge(db, {
        server_key = server_key
        name       = db_name
      })
    }
  ]...)
}

resource "azurerm_mssql_server" "server" {
  for_each = var.servers

  name                          = each.value.name
  resource_group_name           = each.value.resource_group_name
  location                      = each.value.location
  version                       = "12.0" # the current Azure SQL server version
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false # reachable only through the private endpoint
  tags                          = var.tags

  azuread_administrator {
    login_username              = each.value.entra_admin_login
    object_id                   = each.value.entra_admin_object_id
    tenant_id                   = each.value.tenant_id
    azuread_authentication_only = true # no SQL username/password exists at all
  }
}

resource "azurerm_mssql_database" "database" {
  for_each = local.databases

  name                 = each.value.name
  server_id            = azurerm_mssql_server.server[each.value.server_key].id
  sku_name             = each.value.sku_name
  max_size_gb          = each.value.max_size_gb
  storage_account_type = "Local" # backup redundancy: locally redundant is enough for a lab
  tags                 = var.tags
}