locals {
  # Every zone linked to every VNet. Key example: "keyvault/hub"
  links = merge([
    for zone_key, zone_name in var.zones : {
      for vnet_key, vnet_id in var.vnet_links :
      "${zone_key}/${vnet_key}" => {
        zone_key = zone_key
        vnet_key = vnet_key
        vnet_id  = vnet_id
      }
    }
  ]...)
}

resource "azurerm_private_dns_zone" "this" {
  for_each = var.zones

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.links

  name                 = "link-${each.value.vnet_key}"
  private_dns_zone_id  = azurerm_private_dns_zone.this[each.value.zone_key].id
  virtual_network_id   = each.value.vnet_id
  registration_enabled = false # we only resolve names, VMs don't auto-register here
  tags                 = var.tags
}