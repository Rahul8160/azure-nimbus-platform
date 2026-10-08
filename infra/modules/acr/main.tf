locals {
  # One AcrPush role per (registry, principal). Key example: "main/<object-id>"
  pushers = merge([
    for reg_key, reg in var.registries : {
      for pid in reg.push_principal_ids :
      "${reg_key}/${pid}" => {
        registry_key = reg_key
        principal_id = pid
      }
    }
  ]...)
}

resource "azurerm_container_registry" "this" {
  for_each = var.registries

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku
  admin_enabled       = false # no shared username/password; access only via Azure identities
  tags                = var.tags
}

# Who may push images (you now; the pipeline on Day 4)
resource "azurerm_role_assignment" "push" {
  for_each = local.pushers

  scope                = azurerm_container_registry.this[each.value.registry_key].id
  role_definition_name = "AcrPush"
  principal_id         = each.value.principal_id
}