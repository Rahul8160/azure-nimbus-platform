resource "azurerm_container_registry" "this" {
  for_each = var.registries

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku
  admin_enabled       = false # no shared username/password; access only via Azure identities
  tags                = var.tags
}