locals {
  # Key example: "orders/servicebus-send"
  azure_roles = merge([
    for id_key, id in var.identities : {
      for role_key, role in id.azure_roles :
      "${id_key}/${role_key}" => merge(role, { identity_key = id_key })
    }
  ]...)

  # Key example: "inventory/inventory-data"
  cosmos_roles = merge([
    for id_key, id in var.identities : {
      for role_key, role in id.cosmos_roles :
      "${id_key}/${role_key}" => merge(role, { identity_key = id_key })
    }
  ]...)
}

# ---------- The identity ----------
resource "azurerm_user_assigned_identity" "workload" {
  for_each = var.identities

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = var.tags
}

# ---------- Trust: tokens from this cluster, for this service account ----------
resource "azurerm_federated_identity_credential" "aks" {
  for_each = var.identities

  name                      = "fc-aks-${each.value.namespace}-${each.value.service_account}"
  user_assigned_identity_id = azurerm_user_assigned_identity.workload[each.key].id
  audience                  = ["api://AzureADTokenExchange"] # fixed value for workload identity
  issuer                    = each.value.oidc_issuer_url
  subject                   = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
}

# ---------- Azure RBAC roles ----------
resource "azurerm_role_assignment" "azure_role" {
  for_each = local.azure_roles

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.workload[each.value.identity_key].principal_id
}

# ---------- Cosmos DB data-plane roles ----------
resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_data" {
  for_each = local.cosmos_roles

  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  role_definition_id  = each.value.role_definition_id
  principal_id        = azurerm_user_assigned_identity.workload[each.value.identity_key].principal_id
  scope               = each.value.scope
}