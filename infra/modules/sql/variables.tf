variable "servers" {
  description = "Azure SQL logical servers, each with its databases. Server name must be globally unique."
  type = map(object({
    name                  = string
    resource_group_name   = string
    location              = string
    tenant_id             = string
    entra_admin_login     = string # display name for the Entra ID admin
    entra_admin_object_id = string # object ID of the user/group that administers the server

    databases = optional(map(object({
      sku_name    = optional(string, "Basic")
      max_size_gb = optional(number, 2)
    })), {})
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}