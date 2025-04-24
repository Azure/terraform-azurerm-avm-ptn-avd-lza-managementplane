terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0, < 3.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71, < 5.0.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, <4.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.2"
    }
  }
}
