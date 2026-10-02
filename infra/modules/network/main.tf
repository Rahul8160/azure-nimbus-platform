locals {
  # Flatten vnets -> subnets into one map.
  # Key example: "hub/snet-jumpbox"
  subnets = merge([
    for vnet_key, vnet in var.vnets : {
      for subnet_name, subnet in vnet.subnets :
      "${vnet_key}/${subnet_name}" => merge(subnet, {
        name     = subnet_name
        vnet_key = vnet_key
      })
    }
  ]...)

  # Only subnets that asked for an NSG
  nsg_subnets = { for k, s in local.subnets : k => s if s.create_nsg }

  # Flatten subnets -> NSG rules into one map.
  # Key example: "spoke/snet-pe/deny-all-inbound"
  nsg_rules = merge([
    for subnet_key, subnet in local.nsg_subnets : {
      for rule_name, rule in subnet.nsg_rules :
      "${subnet_key}/${rule_name}" => merge(rule, {
        name       = rule_name
        subnet_key = subnet_key
      })
    }
  ]...)
}

# ---------- VNets ----------
resource "azurerm_virtual_network" "this" {
  for_each = var.vnets

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  address_space       = each.value.address_space
  tags                = var.tags
}

# ---------- Subnets ----------
resource "azurerm_subnet" "this" {
  for_each = local.subnets

  name                              = each.value.name
  resource_group_name               = azurerm_virtual_network.this[each.value.vnet_key].resource_group_name
  virtual_network_name              = azurerm_virtual_network.this[each.value.vnet_key].name
  address_prefixes                  = each.value.address_prefixes
  private_endpoint_network_policies = each.value.private_endpoint_network_policies
}

# ---------- NSGs (one per subnet that asked for it) ----------
resource "azurerm_network_security_group" "this" {
  for_each = local.nsg_subnets

  name                = "nsg-${each.value.vnet_key}-${each.value.name}"
  resource_group_name = azurerm_virtual_network.this[each.value.vnet_key].resource_group_name
  location            = azurerm_virtual_network.this[each.value.vnet_key].location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = local.nsg_rules

  name                        = each.value.name
  resource_group_name         = azurerm_network_security_group.this[each.value.subnet_key].resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet_key].name

  priority                   = each.value.priority
  direction                  = each.value.direction
  access                     = each.value.access
  protocol                   = each.value.protocol
  source_port_range          = each.value.source_port_range
  destination_port_range     = each.value.destination_port_range
  destination_port_ranges    = each.value.destination_port_ranges
  source_address_prefix      = each.value.source_address_prefix
  source_address_prefixes    = each.value.source_address_prefixes
  destination_address_prefix = each.value.destination_address_prefix
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.nsg_subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

# ---------- Peering (both directions per entry) ----------
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.peerings

  name                         = "peer-${each.value.hub_key}-to-${each.value.spoke_key}"
  resource_group_name          = azurerm_virtual_network.this[each.value.hub_key].resource_group_name
  virtual_network_name         = azurerm_virtual_network.this[each.value.hub_key].name
  remote_virtual_network_id    = azurerm_virtual_network.this[each.value.spoke_key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = each.value.use_hub_gateway
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.peerings

  name                         = "peer-${each.value.spoke_key}-to-${each.value.hub_key}"
  resource_group_name          = azurerm_virtual_network.this[each.value.spoke_key].resource_group_name
  virtual_network_name         = azurerm_virtual_network.this[each.value.spoke_key].name
  remote_virtual_network_id    = azurerm_virtual_network.this[each.value.hub_key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = each.value.use_hub_gateway
}