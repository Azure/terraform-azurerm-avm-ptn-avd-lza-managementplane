<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.6.6, < 2.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_log_analytics_workspace_location"></a> [log\_analytics\_workspace\_location](#input\_log\_analytics\_workspace\_location)

Description: Location for the Log Analytics workspace

Type: `string`

### <a name="input_virtual_desktop_application_group_location"></a> [virtual\_desktop\_application\_group\_location](#input\_virtual\_desktop\_application\_group\_location)

Description: Location for the virtual desktop application group

Type: `string`

### <a name="input_virtual_desktop_host_pool_location"></a> [virtual\_desktop\_host\_pool\_location](#input\_virtual\_desktop\_host\_pool\_location)

Description: Location for the host pool

Type: `string`

### <a name="input_virtual_desktop_scaling_plan_location"></a> [virtual\_desktop\_scaling\_plan\_location](#input\_virtual\_desktop\_scaling\_plan\_location)

Description: Location for the scaling plan

Type: `string`

### <a name="input_virtual_desktop_workspace_location"></a> [virtual\_desktop\_workspace\_location](#input\_virtual\_desktop\_workspace\_location)

Description: Location for the virtual desktop workspace

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

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

### <a name="input_virtual_desktop_scaling_plan_name"></a> [virtual\_desktop\_scaling\_plan\_name](#input\_virtual\_desktop\_scaling\_plan\_name)

Description: The scaling plan for the AVD Host Pool.

Type: `string`

Default: `"scp-avd-01"`

### <a name="input_virtual_desktop_scaling_plan_time_zone"></a> [virtual\_desktop\_scaling\_plan\_time\_zone](#input\_virtual\_desktop\_scaling\_plan\_time\_zone)

Description: Specifies the Time Zone which should be used by the Scaling Plan for time based events.

Type: `string`

Default: `"GMT Standard Time"`

### <a name="input_virtual_desktop_workspace_name"></a> [virtual\_desktop\_workspace\_name](#input\_virtual\_desktop\_workspace\_name)

Description: The name of the AVD Workspace

Type: `string`

Default: `"vdws-avd-001"`

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