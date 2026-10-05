terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true # destroy removes the vault completely
      recover_soft_deleted_key_vaults = true # re-apply restores a soft-deleted vault with the same name
    }
  }
  # subscription_id is read from the ARM_SUBSCRIPTION_ID environment variable
}