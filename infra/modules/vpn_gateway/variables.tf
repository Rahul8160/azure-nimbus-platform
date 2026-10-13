variable "gateways" {
  description = "Point-to-site VPN gateways with Entra ID (Azure AD) authentication."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    gateway_subnet_id   = string # must be GatewaySubnet
    sku                 = optional(string, "VpnGw1AZ")
    generation          = optional(string, "Generation1")
    zones               = optional(list(string), ["1", "2", "3"])

    # Point-to-site settings
    client_address_space = list(string) # pool handed to VPN clients, e.g. ["172.16.0.0/24"]
    tenant_id            = string
    # Audience of the Microsoft-registered Azure VPN Client app
    aad_audience = optional(string, "c632b3df-fb67-4d84-bdcf-b95ad541b5c8")
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}