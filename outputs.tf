output "application_group_id" {
  description = "The ID of the application group."
  value       = module.avm_res_desktopvirtualization_applicationgroup.resource.id
}

output "hostpool_id" {
  description = "The ID of the host pool."
  value       = module.avm_res_desktopvirtualization_hostpool.resource.id
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace."
  value       = module.avm_res_operationalinsights_workspace.resource.id
}

output "private_endpoints" {
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  value       = azurerm_private_endpoint.this
}

output "registrationinfo_token" {
  description = "The token for the host pool registration."
  sensitive   = true
  value       = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource_id" {
  description = "This output is the full output for the resource to allow flexibility to reference all possible values for the resource. Example usage: module.<modulename>.resource.id"
  value       = module.avm_res_desktopvirtualization_hostpool.resource
}

output "scaling_plan_id" {
  description = "The ID of the scaling plan."
  value       = module.avm_res_desktopvirtualization_scaling_plan.resource.id
}

output "workspace_id" {
  description = "The ID of the workspace."
  value       = module.avm_res_desktopvirtualization_workspace.resource.id
}
