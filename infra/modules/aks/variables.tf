variable "clusters" {
  description = "AKS clusters. Map key is a logical name."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    dns_prefix          = string
    node_resource_group = string # resource group AKS creates for nodes, load balancer, etc.
    subnet_id           = string # node subnet
    acr_id              = string # registry the nodes pull images from
    tenant_id           = string
    admin_object_ids    = list(string)              # get "AKS RBAC Cluster Admin"
    dns_link_vnet_ids   = optional(map(string), {}) # extra VNets that must resolve the private API server

    kubernetes_version = optional(string) # null = latest stable version
    node_vm_size       = optional(string, "Standard_B2s_v2")
    node_count         = optional(number, 1)
    node_os_disk_gb    = optional(number, 30)

    pod_cidr       = optional(string, "192.168.0.0/16")
    service_cidr   = optional(string, "172.20.0.0/16")
    dns_service_ip = optional(string, "172.20.0.10") # must be inside service_cidr
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}