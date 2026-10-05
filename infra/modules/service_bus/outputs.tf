output "namespace_ids" {
  value = { for k, n in azurerm_servicebus_namespace.namespace : k => n.id }
}

output "namespace_fqdns" {
  description = "e.g. sb-nimbus-f786969.servicebus.windows.net (what the app uses as SERVICEBUS_NAMESPACE)"
  value       = { for k, n in azurerm_servicebus_namespace.namespace : k => "${n.name}.servicebus.windows.net" }
}

output "queue_ids" {
  description = "Map of \"namespace/queue\" => queue ID (for queue-scoped roles)"
  value       = { for k, q in azurerm_servicebus_queue.queue : k => q.id }
}