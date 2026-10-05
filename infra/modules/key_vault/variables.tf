variable "vaults" {
  description = "Key Vaults. Name must be globally unique, 3-24 characters."
  type = map(object({
    name                       = string
    resource_group_name        = string
    location                   = string
    sku                        = optional(string, "standard")
    soft_delete_retention_days = optional(number, 7)
    allowed_ip_ranges          = optional(list(string), []) # public IPs allowed through the firewall
    admin_object_ids           = optional(list(string), []) # users/identities given Key Vault Administrator
  }))
}

variable "tenant_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}