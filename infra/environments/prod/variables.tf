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