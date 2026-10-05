variable "namespaces" {
  description = "Service Bus namespaces with their queues. Namespace name must be globally unique."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = optional(string, "Basic")

    queues = optional(map(object({
      max_delivery_count  = optional(number, 3)      # attempts before dead-lettering
      lock_duration       = optional(string, "PT1M") # how long a receiver holds a message
      default_message_ttl = optional(string, "PT1H") # unprocessed messages expire after this
    })), {})
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}