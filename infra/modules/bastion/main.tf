resource "azurerm_bastion_host" "bastion" {
  for_each = var.bastions

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku
  virtual_network_id  = each.value.virtual_network_id # Developer SKU attaches to a VNet, not a subnet
  tags                = var.tags
}