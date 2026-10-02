terraform {
  backend "azurerm" {
    resource_group_name  = "rg-nimbus-tfstate"
    storage_account_name = "stnimbustff78654"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
    use_azuread_auth     = true # use your Azure login, not the storage key
  }
}