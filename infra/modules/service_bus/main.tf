locals {
  # namespaces -> queues. Key example: "main/order-placed"
  queues = merge([
    for ns_key, ns in var.namespaces : {
      for queue_name, queue in ns.queues :
      "${ns_key}/${queue_name}" => merge(queue, {
        namespace_key = ns_key
        name          = queue_name
      })
    }
  ]...)
}

resource "azurerm_servicebus_namespace" "namespace" {
  for_each = var.namespaces

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku
  local_auth_enabled  = false # shared access keys disabled: Entra ID only
  minimum_tls_version = "1.2"
  tags                = var.tags
}

resource "azurerm_servicebus_queue" "queue" {
  for_each = local.queues

  name                                 = each.value.name
  namespace_id                         = azurerm_servicebus_namespace.namespace[each.value.namespace_key].id
  max_delivery_count                   = each.value.max_delivery_count
  lock_duration                        = each.value.lock_duration
  default_message_ttl                  = each.value.default_message_ttl
  dead_lettering_on_message_expiration = false
}