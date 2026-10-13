variable "route_tables" {
  description = "Route tables (UDRs). Each can be attached to several subnets."
  type = map(object({
    name                          = string
    resource_group_name           = string
    location                      = string
    bgp_route_propagation_enabled = optional(bool, false) # false: ignore routes learned from the VPN gateway
    subnet_ids                    = map(string)           # key => subnet ID to attach to

    routes = map(object({
      address_prefix         = string           # e.g. 0.0.0.0/0
      next_hop_type          = string           # VirtualAppliance, Internet, VnetLocal, None
      next_hop_in_ip_address = optional(string) # required for VirtualAppliance
    }))
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}