output "cluster_ids" {
  value = { for k, c in azurerm_kubernetes_cluster.cluster : k => c.id }
}

output "cluster_names" {
  value = { for k, c in azurerm_kubernetes_cluster.cluster : k => c.name }
}

output "oidc_issuer_urls" {
  description = "Needed in Step 2 to federate workload identities"
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => c.oidc_issuer_url }
}

output "private_fqdns" {
  description = "Private DNS name of the API server"
  value       = { for k, c in azurerm_kubernetes_cluster.cluster : k => c.private_fqdn }
}