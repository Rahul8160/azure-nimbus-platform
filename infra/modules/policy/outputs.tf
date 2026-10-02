output "assignment_ids" {
  description = "Map of assignment key => assignment ID"
  value       = { for k, a in azurerm_subscription_policy_assignment.this : k => a.id }
}

output "custom_definition_ids" {
  description = "Map of definition key => definition ID"
  value       = { for k, d in azurerm_policy_definition.this : k => d.id }
}