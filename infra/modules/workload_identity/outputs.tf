output "client_ids" {
  description = "Goes into each Kubernetes service account annotation (Step 4)"
  value       = { for k, i in azurerm_user_assigned_identity.workload : k => i.client_id }
}

output "names" {
  description = "Used to create the SQL database users (Step 3)"
  value       = { for k, i in azurerm_user_assigned_identity.workload : k => i.name }
}

output "principal_ids" {
  value = { for k, i in azurerm_user_assigned_identity.workload : k => i.principal_id }
}