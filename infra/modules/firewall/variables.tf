variable "firewalls" {
  description = "Azure Firewalls (one per hub). Map key is a logical name, e.g. hub."
  type = map(object({
    name                       = string
    resource_group_name        = string
    location                   = string
    firewall_subnet_id         = string # must be AzureFirewallSubnet
    management_subnet_id       = string # must be AzureFirewallManagementSubnet (required by Basic SKU)
    sku_tier                   = optional(string, "Basic")
    log_analytics_workspace_id = optional(string) # null = no diagnostic logs

    # Layer 7: which FQDNs each source range may reach. protocols = { Https = 443, Http = 80 }
    application_rule_collections = optional(map(object({
      priority = number
      action   = optional(string, "Allow")
      rules = map(object({
        source_addresses  = list(string)
        destination_fqdns = list(string)
        protocols         = optional(map(number), { Https = 443 })
      }))
    })), {})

    # Layer 4: IP / port / protocol rules
    network_rule_collections = optional(map(object({
      priority = number
      action   = optional(string, "Allow")
      rules = map(object({
        source_addresses      = list(string)
        destination_addresses = list(string)
        destination_ports     = list(string)
        protocols             = list(string) # TCP, UDP, ICMP, Any
      }))
    })), {})
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}