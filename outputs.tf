
output "azure_virtual_desktop_host_pool" {
  description = "Name of the Azure Virtual Desktop host pool"
  value       = azurerm_virtual_desktop_host_pool.hostpool.name
}

output "azure_virtual_desktop_host_pool_id" {
  description = "ID of the Azure Virtual Desktop host pool"
  value       = azurerm_virtual_desktop_host_pool.hostpool.id
}

output "azurerm_virtual_desktop_application_group" {
  description = "Name of the Azure Virtual Desktop DAG"
  value       = azurerm_virtual_desktop_application_group.dag.name
}

output "azurerm_virtual_desktop_application_group_id" {
  description = "ID of the Azure Virtual Desktop DAG"
  value       = azurerm_virtual_desktop_application_group.dag.id
}

output "azurerm_virtual_desktop_workspace" {
  description = "Name of the Azure Virtual Desktop workspace"
  value       = azurerm_virtual_desktop_workspace.workspace.name
}

output "workspace_id" {
  value       = azurerm_virtual_desktop_workspace.workspace.id
  description = "The ID of the Workspace resource."

# TODO: insert outputs here.

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  value       = azurerm_resource_group.TODO # TODO: Replace this dummy resource azurerm_resource_group.TODO with your module resource
  description = "This is the full output for the resource."

}

output "private_endpoints" {
  value       = azurerm_private_endpoint.this
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
}
