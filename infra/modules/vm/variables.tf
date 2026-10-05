variable "vms" {
  description = "Linux VMs (no public IP). SSH key authentication only."
  type = map(object({
    name                   = string
    resource_group_name    = string
    location               = string
    subnet_id              = string
    ssh_public_key         = string
    size                   = optional(string, "Standard_B2ls_v2")
    admin_username         = optional(string, "azureuser")
    custom_data            = optional(string) # cloud-init script (plain text)
    os_disk_size_gb        = optional(number, 30)
    auto_shutdown_time     = optional(string, "2300") # HHMM, daily
    auto_shutdown_timezone = optional(string, "India Standard Time")
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}