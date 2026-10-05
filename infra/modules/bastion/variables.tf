variable "bastions" {
  description = "Azure Bastion hosts. Developer SKU: free, no subnet or public IP, connects to VMs in the same VNet."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    virtual_network_id  = string
    sku                 = optional(string, "Developer")
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}