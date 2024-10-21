output "application_group_id" {
  description = "The ID of the application group."
  value       = module.avm_res_desktopvirtualization_applicationgroup.resource.id
}

output "dcr_resource_id" {
  description = "The ID of the Monitor Data Collection Rule."
  value       = module.avm-ptn-avd-lza-insights.resource_id
}

output "hostpool_id" {
  description = "The ID of the host pool."
  value       = module.avm_res_desktopvirtualization_hostpool.resource.id
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "private_endpoints_hostpool" {
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  value       = module.avm_res_desktopvirtualization_hostpool.private_endpoints
}

output "registrationinfo_token" {
  description = "The token for the host pool registration."
  sensitive   = true
  value       = module.avm_res_desktopvirtualization_hostpool.registrationinfo_token
}

output "resource" {
  description = "This output is the full output for the resource to allow flexibility to reference all possible values for the resource. Example usage: module.<modulename>.resource.id"
  value       = module.avm_res_desktopvirtualization_hostpool.resource
}

output "resource_id" {
  description = "This output is the full output for the resource to allow flexibility to reference all possible values for the resource. Example usage: module.<modulename>.resource.id"
  value       = module.avm_res_desktopvirtualization_hostpool.resource
}

output "scaling_plan_id" {
  description = "The ID of the scaling plan."
  value       = module.avm_res_desktopvirtualization_scaling_plan.resource.id
}

output "virtual_desktop_host_pool_name" {
  description = "The name of the host pool."
  value       = module.avm_res_desktopvirtualization_hostpool.resource.name
}

output "workspace_id" {
  description = "The ID of the workspace."
  value       = module.avm_res_desktopvirtualization_workspace.resource.id
}
