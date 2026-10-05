variable "accounts" {
  description = "Cosmos DB (NoSQL API) accounts with databases and containers. Account name must be globally unique."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    free_tier_enabled   = optional(bool, true) # only ONE free-tier account allowed per subscription
    consistency_level   = optional(string, "Session")

    databases = optional(map(object({
      containers = map(object({
        partition_key_path = string
        throughput         = optional(number, 400) # RU/s
      }))
    })), {})
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}