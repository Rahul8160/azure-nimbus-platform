variable "resource_groups" {
  description = "Resource groups to create. The map key is a short logical name (e.g. hub)."
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))
}

variable "common_tags" {
  description = "Tags applied to every resource group."
  type        = map(string)
  default     = {}
}