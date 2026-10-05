output "resource_group_names" {
  value = module.resource_groups.names
}

output "vnet_ids" {
  value = module.network.vnet_ids
}

output "subnet_ids" {
  value = module.network.subnet_ids
}


output "policy_assignment_ids" {
  value = module.policy.assignment_ids
}


output "acr_login_servers" {
  value = module.acr.login_servers
}

output "key_vault_uris" {
  value = module.key_vault.uris
}

output "private_endpoint_ips" {
  value = module.private_endpoints.private_ips
}


output "sql_server_fqdns" {
  value = module.sql.server_fqdns
}

output "cosmos_endpoints" {
  value = module.cosmos.endpoints
}

output "servicebus_namespace_fqdns" {
  value = module.service_bus.namespace_fqdns
}


output "aks_cluster_names" {
  value = module.aks.cluster_names
}

output "aks_oidc_issuer_urls" {
  value = module.aks.oidc_issuer_urls
}

output "aks_private_fqdns" {
  value = module.aks.private_fqdns
}