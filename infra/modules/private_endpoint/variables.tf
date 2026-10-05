variable "private_endpoints" {
  description = "Private endpoints. Map key becomes part of the name (pe-<key>)."
  type = map(object({
    resource_group_name  = string
    location             = string
    subnet_id            = string
    resource_id          = string       # the service to connect to (Key Vault, SQL server, ...)
    subresource_names    = list(string) # which part of it: vault, sqlServer, Sql (Cosmos), ...
    private_dns_zone_ids = list(string)
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}