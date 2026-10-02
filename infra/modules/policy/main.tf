data "azurerm_subscription" "current" {}

resource "azurerm_policy_definition" "this" {
  for_each = var.custom_definitions

  name         = each.key
  policy_type  = "Custom"
  mode         = each.value.mode
  display_name = each.value.display_name
  description  = each.value.description
  policy_rule  = each.value.policy_rule
  parameters   = each.value.parameters
}

resource "azurerm_subscription_policy_assignment" "this" {
  for_each = var.assignments

  name            = each.key
  subscription_id = data.azurerm_subscription.current.id
  display_name    = each.value.display_name
  description     = each.value.description
  enforce         = each.value.enforce

  # Custom definition if a key is given, otherwise the built-in ID
  policy_definition_id = (
    each.value.custom_definition_key != null
    ? azurerm_policy_definition.this[each.value.custom_definition_key].id
    : each.value.policy_definition_id
  )

  # Azure expects: { "paramName": { "value": ... } }
  parameters = length(each.value.parameters) > 0 ? jsonencode({
    for name, value in each.value.parameters : name => { value = value }
  }) : null
}