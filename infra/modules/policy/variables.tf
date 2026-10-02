variable "custom_definitions" {
  description = "Custom policy definitions. Map key becomes the definition name."
  type = map(object({
    display_name = string
    description  = optional(string, "")
    mode         = optional(string, "All")
    policy_rule  = string           # JSON string
    parameters   = optional(string) # JSON string
  }))
  default = {}
}

variable "assignments" {
  description = "Policy assignments at subscription scope. Set exactly one of policy_definition_id (built-in) or custom_definition_key (custom)."
  type = map(object({
    display_name          = string
    description           = optional(string, "")
    policy_definition_id  = optional(string)
    custom_definition_key = optional(string)
    parameters            = optional(map(list(string)), {})
    enforce               = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for a in values(var.assignments) :
      (a.policy_definition_id == null) != (a.custom_definition_key == null)
    ])
    error_message = "Each assignment must set exactly one of policy_definition_id or custom_definition_key."
  }
}