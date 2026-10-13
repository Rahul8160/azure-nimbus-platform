locals {
  # accounts -> databases. Key example: "main/nimbus"
  databases = merge([
    for account_key, account in var.accounts : {
      for db_name, db in account.databases :
      "${account_key}/${db_name}" => {
        account_key = account_key
        name        = db_name
        containers  = db.containers
      }
    }
  ]...)

  # databases -> containers. Key example: "main/nimbus/inventory"
  containers = merge([
    for db_key, db in local.databases : {
      for container_name, container in db.containers :
      "${db_key}/${container_name}" => merge(container, {
        database_key = db_key
        account_key  = db.account_key
        name         = container_name
      })
    }
  ]...)
}

resource "azurerm_cosmosdb_account" "account" {
  for_each = var.accounts

  name                          = each.value.name
  resource_group_name           = each.value.resource_group_name
  location                      = each.value.location
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB" # NoSQL API
  free_tier_enabled             = each.value.free_tier_enabled
  public_network_access_enabled = false # reachable only through the private endpoint
  local_authentication_enabled  = false # account keys disabled: Entra ID only
  tags                          = var.tags

  consistency_policy {
    consistency_level = each.value.consistency_level
  }

  automatic_failover_enabled = length(each.value.secondary_locations) > 0

  # Primary region
  geo_location {
    location          = each.value.location
    failover_priority = 0
  }

  # DR regions: priority 1, 2, ... in list order
  dynamic "geo_location" {
    for_each = each.value.secondary_locations
    content {
      location          = geo_location.value
      failover_priority = geo_location.key + 1
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "database" {
  for_each = local.databases

  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.account[each.value.account_key].resource_group_name
  account_name        = azurerm_cosmosdb_account.account[each.value.account_key].name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  for_each = local.containers

  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.account[each.value.account_key].resource_group_name
  account_name        = azurerm_cosmosdb_account.account[each.value.account_key].name
  database_name       = azurerm_cosmosdb_sql_database.database[each.value.database_key].name
  partition_key_paths = [each.value.partition_key_path]
  throughput          = each.value.throughput
}