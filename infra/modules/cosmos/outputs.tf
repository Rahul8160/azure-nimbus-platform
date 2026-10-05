output "account_ids" {
  value = { for k, a in azurerm_cosmosdb_account.account : k => a.id }
}

output "endpoints" {
  description = "e.g. https://cosmos-nimbus-f786969.documents.azure.com:443/ (what the app uses as COSMOS_ENDPOINT)"
  value       = { for k, a in azurerm_cosmosdb_account.account : k => a.endpoint }
}