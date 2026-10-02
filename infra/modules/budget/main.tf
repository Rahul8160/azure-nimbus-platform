data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "this" {
  for_each = var.budgets

  name            = each.key
  subscription_id = data.azurerm_subscription.current.id
  amount          = each.value.amount
  time_grain      = "Monthly"

  time_period {
    start_date = each.value.start_date
    end_date   = each.value.end_date
  }

  # One alert per threshold on ACTUAL spend
  dynamic "notification" {
    for_each = each.value.thresholds
    content {
      enabled        = true
      operator       = "GreaterThanOrEqualTo"
      threshold      = notification.value
      threshold_type = "Actual"
      contact_emails = var.contact_emails
    }
  }

  # One early warning on FORECASTED spend
  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = each.value.forecast_threshold
    threshold_type = "Forecasted"
    contact_emails = var.contact_emails
  }
}