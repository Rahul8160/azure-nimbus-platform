variable "vnets" {
  description = "VNets to create. Map key is a logical name (hub, spoke)."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    address_space       = list(string)

    subnets = optional(map(object({
      address_prefixes                  = list(string)
      private_endpoint_network_policies = optional(string, "Disabled")
      create_nsg                        = optional(bool, false)

      nsg_rules = optional(map(object({
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = optional(string, "*")
        destination_port_range     = optional(string)
        destination_port_ranges    = optional(list(string))
        source_address_prefix      = optional(string)
        source_address_prefixes    = optional(list(string))
        destination_address_prefix = optional(string, "*")
      })), {})
    })), {})
  }))
}

variable "peerings" {
  description = "Hub-spoke peerings. Each entry creates both directions."
  type = map(object({
    hub_key         = string
    spoke_key       = string
    use_hub_gateway = optional(bool, false)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to all network resources"
  type        = map(string)
  default     = {}
}