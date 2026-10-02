output "budget_ids" {
  value = { for k, b in azurerm_consumption_budget_subscription.this : k => b.id }
}