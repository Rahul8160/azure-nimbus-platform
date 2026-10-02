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