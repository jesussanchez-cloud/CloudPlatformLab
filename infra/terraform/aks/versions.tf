terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-cloudplatformlab-tfstate"
    storage_account_name = "stcplabtfstate"
    container_name       = "tfstate"
    key                  = "aks/dev.tfstate"
    use_azuread_auth     = true
  }
}
