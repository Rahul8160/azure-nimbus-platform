variable "registries" {
  description = "Container registries. Name must be globally unique, letters and numbers only."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = optional(string, "Basic")
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}