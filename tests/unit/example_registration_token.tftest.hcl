mock_provider "azapi" {
  mock_data "azapi_resource_action" {
    defaults = {
      output = {}
      sensitive_output = {
        token = "current-mock-registration-token"
      }
    }
  }
}

mock_provider "azuread" {}
mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
    }
  }

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.ManagedIdentity/userAssignedIdentities/example"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.OperationalInsights/workspaces/example"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example/subnets/example"
    }
  }

  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/networkInterfaces/example"
    }
  }

  mock_resource "azurerm_windows_virtual_machine" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Compute/virtualMachines/example"
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.wvd.microsoft.com"
    }
  }
}
mock_provider "modtm" {}
mock_provider "time" {}

mock_provider "random" {
  mock_resource "random_password" {
    defaults = {
      result = "Mock-only-Password123!"
    }
  }

  mock_resource "random_integer" {
    defaults = {
      result = 0
    }
  }
}

override_module {
  target = module.avd
  outputs = {
    hostpool_id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.DesktopVirtualization/hostPools/example"
    registrationinfo_token         = "stale-mock-registration-token"
    virtual_desktop_host_pool_name = "example-host-pool"
    workspace_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.DesktopVirtualization/workspaces/example"
    workspace_name                 = "example-workspace"
  }
}

override_module {
  target = module.avm_ptn_avd_lza_insights
  outputs = {
    resource = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Insights/dataCollectionRules/example"
    }
  }
}

override_module {
  target = module.naming
  outputs = {
    resource_group          = { name_unique = "rg-example" }
    log_analytics_workspace = { name_unique = "law-example" }
    subnet                  = { name_unique = "snet-example" }
    virtual_network         = { name_unique = "vnet-example" }
  }
}

variables {
  enable_telemetry = false
  subscription_id  = "00000000-0000-0000-0000-000000000000"
}

run "default_token" {
  command = apply

  providers = {
    azapi   = azapi
    azuread = azuread
    azurerm = azurerm
    random  = random
    time    = time
  }

  module {
    source = "./examples/default"
  }

  variables {
    vm_count = 2
  }

  assert {
    condition = (
      length(data.azapi_resource_action.registration_token) == 1 &&
      length(azurerm_virtual_machine_extension.vmext_dsc) == 2 &&
      alltrue([
        for extension in azurerm_virtual_machine_extension.vmext_dsc :
        jsondecode(extension.protected_settings).properties.registrationInfoToken == "current-mock-registration-token"
      ])
    )
    error_message = "Every session host must use the current token, not the module's earlier token."
  }

  assert {
    condition     = issensitive(data.azapi_resource_action.registration_token[0].sensitive_output)
    error_message = "The retrieved registration token must stay sensitive."
  }
}

run "default_no_hosts" {
  command = apply

  providers = {
    azapi   = azapi
    azuread = azuread
    azurerm = azurerm
    random  = random
    time    = time
  }

  module {
    source = "./examples/default"
  }

  variables {
    vm_count = 0
  }

  assert {
    condition = (
      length(data.azapi_resource_action.registration_token) == 0 &&
      length(azurerm_virtual_machine_extension.vmext_dsc) == 0
    )
    error_message = "An example without session hosts must not retrieve a registration token."
  }
}

run "private_token" {
  command = apply

  providers = {
    azapi   = azapi
    azuread = azuread
    azurerm = azurerm
    random  = random
    time    = time
  }

  module {
    source = "./examples/private-endpoints"
  }

  variables {
    vm_count = 2
  }

  assert {
    condition = (
      length(data.azapi_resource_action.registration_token) == 1 &&
      length(azurerm_virtual_machine_extension.vmext_dsc) == 2 &&
      alltrue([
        for extension in azurerm_virtual_machine_extension.vmext_dsc :
        jsondecode(extension.protected_settings).properties.registrationInfoToken == "current-mock-registration-token"
      ])
    )
    error_message = "Every session host must use the current token, not the module's earlier token."
  }

  assert {
    condition     = issensitive(data.azapi_resource_action.registration_token[0].sensitive_output)
    error_message = "The retrieved registration token must stay sensitive."
  }
}

run "private_no_hosts" {
  command = apply

  providers = {
    azapi   = azapi
    azuread = azuread
    azurerm = azurerm
    random  = random
    time    = time
  }

  module {
    source = "./examples/private-endpoints"
  }

  variables {
    vm_count = 0
  }

  assert {
    condition = (
      length(data.azapi_resource_action.registration_token) == 0 &&
      length(azurerm_virtual_machine_extension.vmext_dsc) == 0
    )
    error_message = "An example without session hosts must not retrieve a registration token."
  }
}
