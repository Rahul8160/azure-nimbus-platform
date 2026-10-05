variable "project" {
  type    = string
  default = "nimbus"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "owner" {
  description = "Owner tag value"
  type        = string
}

variable "resource_groups" {
  description = "Resource groups for this environment"
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))
}

variable "vnets" {
  description = "VNets. resource_group_key points to an entry in resource_groups. Full type is enforced by the network module."
  type        = any
}

variable "peerings" {
  description = "Hub-spoke peerings"
  type        = any
  default     = {}
}


variable "policy_assignments" {
  description = "Policy assignments (type enforced by the policy module)"
  type        = any
  default     = {}
}

variable "budgets" {
  description = "Subscription budgets (type enforced by the budget module)"
  type        = any
  default     = {}
}

variable "alert_emails" {
  description = "Emails for budget alerts"
  type        = list(string)
}


variable "admin_ip_ranges" {
  description = "Your public IP(s) in CIDR form, allowed through the Key Vault firewall"
  type        = list(string)
}

variable "private_dns_zones" {
  type    = map(string)
  default = {}
}

variable "container_registries" {
  type    = any
  default = {}
}

variable "key_vaults" {
  type    = any
  default = {}
}

variable "private_endpoints" {
  type    = any
  default = {}
}


variable "sql_servers" {
  type    = any
  default = {}
}

variable "cosmos_accounts" {
  type    = any
  default = {}
}

variable "servicebus_namespaces" {
  type    = any
  default = {}
}


variable "aks_clusters" {
  type    = any
  default = {}
}