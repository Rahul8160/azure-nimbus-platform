locals {
  # One role assignment per (vault, admin). Key example: "main/<object-id>"
  admin_assignments = merge([
    for vault_key, vault in var.vaults : {
      for object_id in vault.admin_object_ids :
      "${vault_key}/${object_id}" => {
        vault_key = vault_key
        object_id = object_id
      }
    }
  ]...)
}

resource "azurerm_key_vault" "this" {
  for_each = var.vaults

  name                       = each.value.name
  resource_group_name        = each.value.resource_group_name
  location                   = each.value.location
  tenant_id                  = var.tenant_id
  sku_name                   = each.value.sku
  rbac_authorization_enabled = true  # permissions via Azure RBAC roles, not access policies
  purge_protection_enabled   = false # allows full deletion on destroy (lab setting; true in production)
  soft_delete_retention_days = each.value.soft_delete_retention_days
  tags                       = var.tags

  # Public endpoint stays on, but its firewall denies everything except listed IPs.
  # Resources inside the VNets use the private endpoint instead.
  public_network_access_enabled = true
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = each.value.allowed_ip_ranges
  }
}

resource "azurerm_role_assignment" "admin" {
  for_each = local.admin_assignments

  scope                = azurerm_key_vault.this[each.value.vault_key].id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value.object_id
}