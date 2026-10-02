variable "budgets" {
  description = "Monthly subscription budgets. Map key becomes the budget name."
  type = map(object({
    amount             = number
    start_date         = string # first day of a month, e.g. 2026-10-01T00:00:00Z
    end_date           = optional(string)
    thresholds         = optional(list(number), [25, 50, 75, 100]) # % of actual spend
    forecast_threshold = optional(number, 100)                     # % of forecasted spend
  }))
  default = {}
}

variable "contact_emails" {
  description = "Who receives budget alerts"
  type        = list(string)
}