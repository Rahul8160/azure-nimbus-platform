locals {
  # One association per (route table, subnet). Key example: "jumpbox-egress/hub/snet-jumpbox"
  associations = merge([
    for rt_key, rt in var.route_tables : {
      for subnet_key, subnet_id in rt.subnet_ids :
      "${rt_key}/${subnet_key}" => { route_table_key = rt_key, subnet_id = subnet_id }
    }
  ]...)
}

resource "azurerm_route_table" "route_table" {
  for_each = var.route_tables

  name                          = each.value.name
  resource_group_name           = each.value.resource_group_name
  location                      = each.value.location
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  tags                          = var.tags

  dynamic "route" {
    for_each = each.value.routes
    content {
      name                   = route.key
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }
}

resource "azurerm_subnet_route_table_association" "association" {
  for_each = local.associations

  subnet_id      = each.value.subnet_id
  route_table_id = azurerm_route_table.route_table[each.value.route_table_key].id
}