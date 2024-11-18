<!-- BEGIN_TF_DOCS -->
# Default example

This is a repo for Terraform Azure Verified Module for Azure Virtual Desktop

## Features
- Azure Virtual Desktop Host Pool includes Diagnostic log settings
- Azure Virtual Desktop Desktop Application Group
- Azure Virtual Desktop Workspace includes Diagnostic log settings
- Azure Virtual Desktop Scaling
- Azure Virtual Desktop Insights with Log Analytics workspace
- An AVD session host joined to Entra ID
- Azure Virtual Dekstop Spoke network resources: vnet, subnet
- Azure Key Vault

```hcl
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.6.6, < 2.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.6.0, <4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_monitor_data_collection_rule_association.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule_association) (resource)
- [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.this_subnet_1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_user_assigned_identity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_machine_extension.aadjoin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) (resource)
- [azurerm_virtual_machine_extension.ama](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) (resource)
- [azurerm_virtual_machine_extension.vmext_dsc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) (resource)
- [azurerm_virtual_network.this_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_windows_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) (resource)
- [random_password.vmpass](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_avd_vm_name"></a> [avd\_vm\_name](#input\_avd\_vm\_name)

Description: Base name for the Azure Virtual Desktop VMs

Type: `string`

Default: `"vm-avd"`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_log_analytics_workspace_location"></a> [log\_analytics\_workspace\_location](#input\_log\_analytics\_workspace\_location)

Description: Location for the Log Analytics workspace

Type: `string`

Default: `"centralus"`

### <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name)

Description: The name of the Log Analytics workspace for Azure Virtual Desktop.

Type: `string`

Default: `"avd-log-analytics-workspace"`

### <a name="input_monitor_data_collection_rule_location"></a> [monitor\_data\_collection\_rule\_location](#input\_monitor\_data\_collection\_rule\_location)

Description: The location for the monitor data collection rule.

Type: `string`

Default: `"centralus"`

### <a name="input_monitor_data_collection_rule_resource_group_name"></a> [monitor\_data\_collection\_rule\_resource\_group\_name](#input\_monitor\_data\_collection\_rule\_resource\_group\_name)

Description: The resource group for the monitor data collection rule.

Type: `string`

Default: `"RG-AVDdemo"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: A map of tags to add to all resources

Type: `map(string)`

Default:

```json
{
  "Owner.Email": "name@microsoft.com"
}
```

### <a name="input_virtual_desktop_application_group_location"></a> [virtual\_desktop\_application\_group\_location](#input\_virtual\_desktop\_application\_group\_location)

Description: Location for the virtual desktop application group

Type: `string`

Default: `"centralus"`

### <a name="input_virtual_desktop_application_group_name"></a> [virtual\_desktop\_application\_group\_name](#input\_virtual\_desktop\_application\_group\_name)

Description: The name of the AVD Application Group.

Type: `string`

Default: `"vdag-avd-001"`

### <a name="input_virtual_desktop_application_group_type"></a> [virtual\_desktop\_application\_group\_type](#input\_virtual\_desktop\_application\_group\_type)

Description: The type of the AVD Application Group. Valid values are 'Desktop' and 'RemoteApp'.

Type: `string`

Default: `"Desktop"`

### <a name="input_virtual_desktop_host_pool_friendly_name"></a> [virtual\_desktop\_host\_pool\_friendly\_name](#input\_virtual\_desktop\_host\_pool\_friendly\_name)

Description: (Optional) A friendly name for the Virtual Desktop Host Pool.

Type: `string`

Default: `"AVD Host Pool"`

### <a name="input_virtual_desktop_host_pool_load_balancer_type"></a> [virtual\_desktop\_host\_pool\_load\_balancer\_type](#input\_virtual\_desktop\_host\_pool\_load\_balancer\_type)

Description: `BreadthFirst` load balancing distributes new user sessions across all available session hosts in the host pool. Possible values are `BreadthFirst`, `DepthFirst` and `Persistent`. `DepthFirst` load balancing distributes new user sessions to an available session host with the highest number of connections but has not reached its maximum session limit threshold. `Persistent` should be used if the host pool type is `Personal`

Type: `string`

Default: `"BreadthFirst"`

### <a name="input_virtual_desktop_host_pool_location"></a> [virtual\_desktop\_host\_pool\_location](#input\_virtual\_desktop\_host\_pool\_location)

Description: Location for the host pool

Type: `string`

Default: `"centralus"`

### <a name="input_virtual_desktop_host_pool_maximum_sessions_allowed"></a> [virtual\_desktop\_host\_pool\_maximum\_sessions\_allowed](#input\_virtual\_desktop\_host\_pool\_maximum\_sessions\_allowed)

Description: (Optional) A valid integer value from 0 to 999999 for the maximum number of users that have concurrent sessions on a session host. Should only be set if the `type` of your Virtual Desktop Host Pool is `Pooled`.

Type: `number`

Default: `16`

### <a name="input_virtual_desktop_host_pool_name"></a> [virtual\_desktop\_host\_pool\_name](#input\_virtual\_desktop\_host\_pool\_name)

Description: The name of the AVD Host Pool

Type: `string`

Default: `"vdpool-avd-001"`

### <a name="input_virtual_desktop_host_pool_start_vm_on_connect"></a> [virtual\_desktop\_host\_pool\_start\_vm\_on\_connect](#input\_virtual\_desktop\_host\_pool\_start\_vm\_on\_connect)

Description: (Optional) Enables or disables the Start VM on Connection Feature. Defaults to `false`.

Type: `bool`

Default: `true`

### <a name="input_virtual_desktop_host_pool_type"></a> [virtual\_desktop\_host\_pool\_type](#input\_virtual\_desktop\_host\_pool\_type)

Description: The type of the AVD Host Pool. Valid values are 'Pooled' and 'Personal'.

Type: `string`

Default: `"Pooled"`

### <a name="input_virtual_desktop_scaling_plan_location"></a> [virtual\_desktop\_scaling\_plan\_location](#input\_virtual\_desktop\_scaling\_plan\_location)

Description: Location for the scaling plan

Type: `string`

Default: `"centralus"`

### <a name="input_virtual_desktop_scaling_plan_name"></a> [virtual\_desktop\_scaling\_plan\_name](#input\_virtual\_desktop\_scaling\_plan\_name)

Description: The scaling plan for the AVD Host Pool.

Type: `string`

Default: `"scp-avd-01"`

### <a name="input_virtual_desktop_scaling_plan_time_zone"></a> [virtual\_desktop\_scaling\_plan\_time\_zone](#input\_virtual\_desktop\_scaling\_plan\_time\_zone)

Description: Specifies the Time Zone which should be used by the Scaling Plan for time based events.

Type: `string`

Default: `"GMT Standard Time"`

### <a name="input_virtual_desktop_workspace_location"></a> [virtual\_desktop\_workspace\_location](#input\_virtual\_desktop\_workspace\_location)

Description: Location for the virtual desktop workspace

Type: `string`

Default: `"centralus"`

### <a name="input_virtual_desktop_workspace_name"></a> [virtual\_desktop\_workspace\_name](#input\_virtual\_desktop\_workspace\_name)

Description: The name of the AVD Workspace

Type: `string`

Default: `"vdws-avd-001"`

### <a name="input_vm_count"></a> [vm\_count](#input\_vm\_count)

Description: Number of virtual machines to create

Type: `number`

Default: `1`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_avd"></a> [avd](#module\_avd)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->