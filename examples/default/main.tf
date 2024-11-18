terraform {
  required_version = ">= 1.6.6, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, <4.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "centralus"
  name     = "RG-AVDdemo"
  tags     = var.tags
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-avd-dcr"
  resource_group_name = azurerm_resource_group.this.name
}
resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-avd-dcr"
  resource_group_name = azurerm_resource_group.this.name
}

module "avd" {
  source = "../../"
  # source             = "Azure/avm-ptn-avd-lza-managementplane/azurerm"
  enable_telemetry                   = var.enable_telemetry
  resource_group_name                = azurerm_resource_group.this.name
  virtual_desktop_workspace_name     = var.virtual_desktop_workspace_name
  virtual_desktop_workspace_location = var.virtual_desktop_workspace_location
  public_network_access_enabled      = false
  virtual_desktop_scaling_plan_schedule = [
    {
      name                                 = "Weekends"
      days_of_week                         = ["Saturday", "Sunday"]
      ramp_up_start_time                   = "06:00"
      ramp_up_load_balancing_algorithm     = "BreadthFirst"
      ramp_up_minimum_hosts_percent        = 20
      ramp_up_capacity_threshold_percent   = 10
      peak_start_time                      = "10:00"
      peak_load_balancing_algorithm        = "BreadthFirst"
      ramp_down_start_time                 = "18:00"
      ramp_down_load_balancing_algorithm   = "DepthFirst"
      ramp_down_minimum_hosts_percent      = 10
      ramp_down_force_logoff_users         = false
      ramp_down_wait_time_minutes          = 45
      ramp_down_notification_message       = "Please log off in the next 45 minutes..."
      ramp_down_capacity_threshold_percent = 5
      ramp_down_stop_hosts_when            = "ZeroSessions"
      off_peak_start_time                  = "22:00"
      off_peak_load_balancing_algorithm    = "DepthFirst"
    }
  ]
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
  monitor_data_collection_rule_name                  = "microsoft-avdi-eastus"
  monitor_data_collection_rule_location              = var.monitor_data_collection_rule_location
  monitor_data_collection_rule_resource_group_name   = var.monitor_data_collection_rule_resource_group_name
  log_analytics_workspace_location                   = var.log_analytics_workspace_location
  log_analytics_workspace_name                       = var.log_analytics_workspace_name
  log_analytics_workspace_tags                       = var.tags

}

# Deploy an vnet and subnet for AVD session hosts
resource "azurerm_virtual_network" "this_vnet" {
  address_space       = ["10.1.6.0/26"]
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this_subnet_1" {
  address_prefixes     = ["10.1.6.0/27"]
  name                 = "${module.naming.subnet.name_unique}-1"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this_vnet.name
}

# Deploy a single AVD session host using marketplace image
resource "azurerm_network_interface" "this" {
  count = var.vm_count

  location                       = azurerm_resource_group.this.location
  name                           = "${var.avd_vm_name}-${count.index}-nic"
  resource_group_name            = azurerm_resource_group.this.name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.this_subnet_1.id
  }
}

# Generate VM local password
resource "random_password" "vmpass" {
  length  = 20
  special = true
}

resource "azurerm_windows_virtual_machine" "this" {
  count = var.vm_count

  admin_password             = random_password.vmpass.result
  admin_username             = "adminuser"
  location                   = azurerm_resource_group.this.location
  name                       = "${var.avd_vm_name}-${count.index}"
  network_interface_ids      = [azurerm_network_interface.this[count.index].id]
  resource_group_name        = azurerm_resource_group.this.name
  size                       = "Standard_D4s_v4"
  computer_name              = "${var.avd_vm_name}-${count.index}"
  encryption_at_host_enabled = true
  secure_boot_enabled        = true
  vtpm_enabled               = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    name                 = "${var.avd_vm_name}-${count.index}-osdisk"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }
  source_image_reference {
    offer     = "windows-11"
    publisher = "microsoftwindowsdesktop"
    sku       = "win11-23h2-avd"
    version   = "latest"
  }
}

# Virtual Machine Extension for AMA agent
resource "azurerm_virtual_machine_extension" "ama" {
  count = var.vm_count

  name                      = "AzureMonitorWindowsAgent-${count.index}"
  publisher                 = "Microsoft.Azure.Monitor"
  type                      = "AzureMonitorWindowsAgent"
  type_handler_version      = "1.3"
  virtual_machine_id        = azurerm_windows_virtual_machine.this[count.index].id
  automatic_upgrade_enabled = true

  depends_on = [module.avd]
}

# Virtual Machine Extension for AAD Join
resource "azurerm_virtual_machine_extension" "aadjoin" {
  count = var.vm_count

  name                       = "${var.avd_vm_name}-${count.index}-aadJoin"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  virtual_machine_id         = azurerm_windows_virtual_machine.this[count.index].id
  auto_upgrade_minor_version = true
}

# Virtual Machine Extension for AVD Agent
resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count = var.vm_count

  name                       = "${var.avd_vm_name}-${count.index}-avd_dsc"
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  virtual_machine_id         = azurerm_windows_virtual_machine.this[count.index].id
  auto_upgrade_minor_version = true
  protected_settings         = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${module.avd.registrationinfo_token}"
    }
  }
PROTECTED_SETTINGS
  settings                   = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${module.avd.virtual_desktop_host_pool_name}"
    }
 } 
  SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.aadjoin,
    module.avd
  ]
}

# Creates an association between an Azure Monitor data collection rule and a virtual machine.
resource "azurerm_monitor_data_collection_rule_association" "example" {
  count = var.vm_count

  target_resource_id      = azurerm_windows_virtual_machine.this[count.index].id
  data_collection_rule_id = module.avd.dcr_resource_id.id
  name                    = "${var.avd_vm_name}-association-${count.index}"
}
