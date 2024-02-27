# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  friendly_name                 = var.name
  description                   = var.description
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = local.tags
}

# Create Diagnostic Settings for AVD workspace
resource "azurerm_monitor_diagnostic_setting" "this1" {
  for_each                       = var.diagnostic_settings
  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azurerm_virtual_desktop_workspace.workspace.id
  storage_account_id             = each.value.storage_account_resource_id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  partner_solution_id            = each.value.marketplace_partner_resource_id
  log_analytics_workspace_id     = each.value.workspace_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = each.value.log_groups
    content {
      category_group = enabled_log.value
    }
  }
}

resource "azurerm_role_assignment" "this1" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_virtual_desktop_workspace.workspace.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}

resource "azurerm_management_lock" "this1" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_virtual_desktop_workspace.workspace.id
  lock_level = var.lock.kind
}
