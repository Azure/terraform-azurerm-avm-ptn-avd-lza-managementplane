terraform {
  required_version = ">= 1.6.6, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = module.naming.resource_group.name_unique
}


module "avd" {
  source = "../../"
  # source             = "Azure/avm-ptn-avd-lza-managementplane/azurerm"
  enable_telemetry                                   = var.enable_telemetry
  resource_group_name                                = azurerm_resource_group.this.name
  virtual_desktop_workspace_name                     = var.virtual_desktop_workspace_name
  virtual_desktop_workspace_location                 = var.virtual_desktop_workspace_location
  virtual_desktop_scaling_plan_time_zone             = var.virtual_desktop_scaling_plan_time_zone
  virtual_desktop_scaling_plan_name                  = var.virtual_desktop_scaling_plan_name
  virtual_desktop_scaling_plan_location              = var.virtual_desktop_scaling_plan_location
  virtual_desktop_host_pool_type                     = var.virtual_desktop_host_pool_type
  virtual_desktop_host_pool_load_balancer_type       = var.virtual_desktop_host_pool_load_balancer_type
  virtual_desktop_host_pool_name                     = var.virtual_desktop_host_pool_name
  virtual_desktop_host_pool_location                 = var.virtual_desktop_host_pool_location
  virtual_desktop_host_pool_maximum_sessions_allowed = var.virtual_desktop_host_pool_maximum_sessions_allowed
  virtual_desktop_host_pool_start_vm_on_connect      = var.virtual_desktop_host_pool_start_vm_on_connect
  virtual_desktop_application_group_type             = var.virtual_desktop_application_group_type
  virtual_desktop_application_group_name             = var.virtual_desktop_application_group_name
  virtual_desktop_application_group_location         = var.virtual_desktop_application_group_location
  virtual_desktop_host_pool_friendly_name            = var.virtual_desktop_host_pool_friendly_name
  log_analytics_workspace_name                       = module.naming.log_analytics_workspace.name_unique
  log_analytics_workspace_location                   = var.log_analytics_workspace_location
}
