variable "identities" {
  description = "One managed identity per workload, federated to a Kubernetes service account."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    oidc_issuer_url     = string # the AKS cluster's OIDC issuer
    namespace           = string # Kubernetes namespace of the service account
    service_account     = string # Kubernetes service account name

    # Normal Azure RBAC roles (Service Bus, Key Vault, ...)
    azure_roles = optional(map(object({
      scope = string
      role  = string
    })), {})

    # Cosmos DB data-plane roles (read/write items)
    cosmos_roles = optional(map(object({
      account_name        = string
      resource_group_name = string
      scope               = string # account ID + optional /dbs/<db>/colls/<container>
      role_definition_id  = string
    })), {})
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}