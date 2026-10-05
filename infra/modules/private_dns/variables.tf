variable "zones" {
  description = "Private DNS zones. Map key is a logical name (keyvault, sql, cosmos)."
  type        = map(string)
}

variable "resource_group_name" {
  description = "Resource group that holds all zones (the hub)"
  type        = string
}

variable "vnet_links" {
  description = "VNets to link every zone to. Map key => VNet ID."
  type        = map(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}