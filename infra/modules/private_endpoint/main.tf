resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = "pe-${each.key}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  subnet_id           = each.value.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${each.key}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = false # we own both sides, so it's approved automatically
  }

  # Azure writes the A record (name -> private IP) into these zones automatically
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = each.value.private_dns_zone_ids
  }
}