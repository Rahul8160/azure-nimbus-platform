variable "failover_groups" {
  description = "SQL failover groups: replicate databases to a partner server in another region."
  type = map(object({
    name                = string # globally unique; becomes <name>.database.windows.net
    primary_server_id   = string
    secondary_server_id = string
    database_ids        = list(string)
    grace_minutes       = optional(number, 60) # how long Azure waits before automatic failover
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}