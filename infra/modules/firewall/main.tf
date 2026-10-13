locals {
  # Two public IPs per firewall: one for traffic, one for management (Basic SKU requirement).
  # Key example: "hub/data", "hub/mgmt"
  public_ips = merge([
    for fw_key, fw in var.firewalls : {
      "${fw_key}/data" = { firewall_key = fw_key, suffix = "data" }
      "${fw_key}/mgmt" = { firewall_key = fw_key, suffix = "mgmt" }
    }
  ]...)

  # Only firewalls that actually define rules get a rule collection group
  firewalls_with_rules = {
    for k, fw in var.firewalls : k => fw
    if length(fw.application_rule_collections) + length(fw.network_rule_collections) > 0
  }

  firewalls_with_logs = {
    for k, fw in var.firewalls : k => fw if fw.log_analytics_workspace_id != null
  }
}

# ---------- Public IPs ----------
resource "azurerm_public_ip" "firewall" {
  for_each = local.public_ips

  name                = "pip-${var.firewalls[each.value.firewall_key].name}-${each.value.suffix}"
  resource_group_name = var.firewalls[each.value.firewall_key].resource_group_name
  location            = var.firewalls[each.value.firewall_key].location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# ---------- Policy: holds the rules, separate from the firewall itself ----------
resource "azurerm_firewall_policy" "policy" {
  for_each = var.firewalls

  name                = "afwp-${each.value.name}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku_tier
  tags                = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "rules" {
  for_each = local.firewalls_with_rules

  name               = "rcg-default"
  firewall_policy_id = azurerm_firewall_policy.policy[each.key].id
  priority           = 200

  dynamic "application_rule_collection" {
    for_each = each.value.application_rule_collections
    content {
      name     = application_rule_collection.key
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name              = rule.key
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.key
              port = protocols.value
            }
          }
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = each.value.network_rule_collections
    content {
      name     = network_rule_collection.key
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.key
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
          protocols             = rule.value.protocols
        }
      }
    }
  }
}

# ---------- The firewall ----------
resource "azurerm_firewall" "firewall" {
  for_each = var.firewalls

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku_name            = "AZFW_VNet"
  sku_tier            = each.value.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.policy[each.key].id
  tags                = var.tags

  ip_configuration {
    name                 = "data"
    subnet_id            = each.value.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall["${each.key}/data"].id
  }

  management_ip_configuration {
    name                 = "mgmt"
    subnet_id            = each.value.management_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall["${each.key}/mgmt"].id
  }
}

# ---------- Logs: allowed/denied decisions, queryable with KQL ----------
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  for_each = local.firewalls_with_logs

  name                           = "diag-${each.value.name}"
  target_resource_id             = azurerm_firewall.firewall[each.key].id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated" # resource-specific tables, e.g. AZFWApplicationRule

  enabled_log {
    category_group = "allLogs"
  }
}