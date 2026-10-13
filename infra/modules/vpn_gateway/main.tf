resource "azurerm_public_ip" "gateway" {
  for_each = var.gateways

  name                = "pip-${each.value.name}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = each.value.zones # AZ gateway SKUs need a zone-redundant IP
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "gateway" {
  for_each = var.gateways

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = each.value.sku
  generation          = each.value.generation
  active_active       = false
  tags                = var.tags

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.gateway[each.key].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = each.value.gateway_subnet_id
  }

  # Point-to-site: laptops connect with the Azure VPN Client and sign in with Entra ID
  vpn_client_configuration {
    address_space        = each.value.client_address_space
    vpn_client_protocols = ["OpenVPN"]
    vpn_auth_types       = ["AAD"]

    aad_tenant   = "https://login.microsoftonline.com/${each.value.tenant_id}/"
    aad_issuer   = "https://sts.windows.net/${each.value.tenant_id}/"
    aad_audience = each.value.aad_audience
  }
}