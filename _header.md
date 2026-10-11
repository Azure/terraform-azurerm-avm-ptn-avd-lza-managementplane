# terraform-azurerm-avm-ptn-avd-lza-managementplane

This is a repo for Terraform Azure Verified Module for Azure Virtual Desktop

## Features
- Azure Virtual Desktop Host Pool includes Diagnostic log settings
- Azure Virtual Desktop Application Group
- Azure Virtual Desktop Workspace includes Diagnostic log settings
- Azure Virtual Desktop Scaling

## Upgrading existing deployments

Earlier versions also tracked host-pool registration information at `azurerm_virtual_desktop_host_pool_registration_info.registrationinfo`. On upgrade, Terraform forgets this duplicate state entry without deleting the Azure registration information. The host-pool child continues to manage it and provide the registration token; no manual state migration is required.
